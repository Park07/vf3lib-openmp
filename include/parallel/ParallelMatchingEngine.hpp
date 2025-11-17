#ifndef PARALLELMATCHINGTHREADPOOL_HPP
#define PARALLELMATCHINGTHREADPOOL_HPP

#include <omp.h>
#include <vector>
#include <stack>
#include <atomic>
#include <cstdint>

#ifndef WIN32
#include <unistd.h>
#include <sys/time.h>
#else
#include <Windows.h>
#include <stdint.h>
#endif

#include "WindowsTime.h"
#include "ARGraph.hpp"
#include "MatchingEngine.hpp"
#include "Stack.hpp"

namespace vflib {

typedef unsigned short ThreadId;
constexpr ThreadId NULL_THREAD = (std::numeric_limits<ThreadId>::max)();

template<typename T>
class OpenMPStack : public Stack<T> {
private:
    std::stack<T> data_stack;
    omp_lock_t stack_lock;
    std::atomic<size_t> count;

public:
    OpenMPStack() : count(0) {
        omp_init_lock(&stack_lock);
    }

    ~OpenMPStack() {
        omp_destroy_lock(&stack_lock);
    }

    void push(T const& data) {
        omp_set_lock(&stack_lock);
        data_stack.push(data);
        count++;
        omp_unset_lock(&stack_lock);
    }

    T pop() {
        T res = nullptr;
        omp_set_lock(&stack_lock);
        if (!data_stack.empty()) {
            res = data_stack.top();
            data_stack.pop();
            count--;
        }
        omp_unset_lock(&stack_lock);
        return res;
    }

    size_t size() {
        return count.load();
    }
};

template<typename VFState>
class ParallelMatchingEngine : public MatchingEngine<VFState>
{
protected:
    using MatchingEngine<VFState>::solutions;
    using MatchingEngine<VFState>::visit;
    using MatchingEngine<VFState>::solCount;
    using MatchingEngine<VFState>::storeSolutions;
    using MatchingEngine<VFState>::fist_solution_time;

    struct timeval start_time;
    struct timeval pool_time;
    struct timeval exit_time;
    struct timeval eos_time;

    bool once;
    int16_t cpu;
    int16_t numThreads;
    std::atomic<int32_t> statesToBeExplored;
    Stack<VFState*>* globalStateStack;

    virtual void PreMatching(VFState* s){};
    virtual void PreprocessState(ThreadId thread_id){};
    virtual void PostprocessState(ThreadId thread_id){};
    virtual void UnprocessedState(ThreadId thread_id){};

    virtual void PutState(VFState* s, ThreadId thread_id) {
        globalStateStack->push(s);
    }

    virtual void GetState(VFState** res, ThreadId thread_id) {
        *res = globalStateStack->pop();
    }

    inline unsigned GetRemainingStates() {
        return globalStateStack->size();
    }

    // FIXED: Use pthread's exact termination logic
    void Run(ThreadId thread_id) {
        VFState* s = NULL;
        
        while(statesToBeExplored > 0) {
            GetState(&s, thread_id);
            if(s) {
                PreprocessState(thread_id);
                ProcessState(s, thread_id);
                statesToBeExplored--;
                delete s;
                PostprocessState(thread_id);
            }
            UnprocessedState(thread_id);
        }
        
        #pragma omp critical(end_time)
        {
            gettimeofday(&(eos_time), NULL);
        }
    }

    bool ProcessState(VFState *s, ThreadId thread_id) {
        if (s->IsGoal()) {
            #pragma omp critical(first_solution)
            {
                if (!once) {
                    once = true;
                    gettimeofday(&(this->fist_solution_time), NULL);
                }
            }

            solCount++;
            
            if(storeSolutions) {
                #pragma omp critical(solution_storage)
                {
                    MatchingSolution sol;
                    s->GetCoreSet(sol);
                    solutions.push_back(sol);
                }
            }
            
            if (visit) {
                return (*visit)(*s);
            }
            return true;
        }

        if (s->IsDead())
            return false;

        nodeID_t n1 = NULL_NODE, n2 = NULL_NODE;
        while (s->NextPair(&n1, &n2, n1, n2)) {
            if (s->IsFeasiblePair(n1, n2)) {
                ExploreState(s, n1, n2, thread_id);
            }
        }
        return false;
    }

    virtual void ExploreState(VFState *s, nodeID_t n1, nodeID_t n2, ThreadId thread_id) {
        statesToBeExplored++;
        
        VFState* s1 = new VFState(*s);
        s1->AddPair(n1, n2);
        PutState(s1, thread_id);
    }

public:
    ParallelMatchingEngine(unsigned short int numThreads, 
        bool storeSolutions = false,
        bool lockFree = false,
        short int cpu = -1,
        MatchingVisitor<VFState> *visit = NULL):
        MatchingEngine<VFState>(visit, storeSolutions),
        once(false),
        cpu(cpu),
        numThreads(numThreads),
        statesToBeExplored(0) {
            
            globalStateStack = new OpenMPStack<VFState*>();
            
            if (cpu > -1) {
                omp_set_num_threads(numThreads);
            }
        }

    ~ParallelMatchingEngine() {
        delete globalStateStack;
    }

    bool FindAllMatchings(VFState& s) {
        statesToBeExplored = 1;
        
        PreMatching(&s);
        gettimeofday(&(this->start_time), NULL);
        
        VFState* s0 = new VFState(s);
        PutState(s0, NULL_THREAD);
        
        gettimeofday(&(this->pool_time), NULL);
        
        #pragma omp parallel num_threads(numThreads)
        {
            ThreadId thread_id = omp_get_thread_num();
            Run(thread_id);
        }
        
        gettimeofday(&(this->exit_time), NULL);
        
        return true;
    }

    inline size_t GetThreadCount() const {
        return numThreads;
    }

    void ResetSolutionCounter() {
        solCount = 0;
        once = false;
    }
};

}

#endif
