# Crossover and Recombination Operators for Evolutionary Prompt Optimization

**Date:** 2026-03-17
**Context:** Claude Resonance — evolving system prompts to maximize Claude's engagement quality
**Status:** Research complete; recommendations ready for implementation

---

## 1. Classical Crossover Theory: Building Blocks and Schema

### The Schema Theorem

Holland's Schema Theorem (1975) provides the foundational theoretical justification for genetic algorithms. A **schema** is a template pattern over the genome — in a binary GA, something like `1**0*1` where `*` is a wildcard. The theorem states that short, low-order, above-average schemata receive exponentially increasing representation in subsequent generations. In other words: if a partial pattern is associated with high fitness, selection will amplify it.

The key parameters for a schema are:
- **Order**: how many fixed positions (fewer = more robust to crossover disruption)
- **Defining length**: the distance between the outermost fixed positions (shorter = less likely to be broken by single-point crossover)

**Citation:** Holland, J.H. (1975). *Adaptation in Natural and Artificial Systems*. University of Michigan Press.

### The Building Block Hypothesis

Goldberg extended Holland's work into the **Building Block Hypothesis (BBH)**: GAs work by discovering short, low-order, high-fitness schemata ("building blocks") and recombining them via crossover into progressively higher-fitness solutions. The idea is that crossover is the primary mechanism for *assembling* partial solutions, while mutation provides background variation.

**Citation:** Goldberg, D.E. (1989). *Genetic Algorithms in Search, Optimization, and Machine Learning*. Addison-Wesley.

### Known Failure Modes

The BBH has been extensively critiqued and its limitations are well-understood:

1. **Epistasis**: When the fitness contribution of one gene depends on the value of another gene, crossover can destroy good combinations. Conventional crossover operators have "serious performance problems" on functions with epistasis among parameters, because they cannot preserve the joint distribution of interacting variables.

2. **Hitchhiking**: Low-fitness alleles can "hitchhike" alongside high-fitness alleles if they are physically linked (nearby in the genome). This leads to convergence on suboptimal solutions.

3. **Linkage problems**: If building blocks span positions that are far apart in the genome, single-point crossover will frequently disrupt them. This led to an entire subfield of **linkage learning** — algorithms like the Linkage Tree Genetic Algorithm (LTGA) that learn which variables interact before recombining them (Harik & Goldberg, 1996; Thierens & Bosman, 2011).

4. **Deception**: Some problems have low-order building blocks that point *away* from the global optimum, actively misleading the GA.

**Key critique:** The BBH assumes building blocks are *separable* — that you can identify and recombine them independently. For natural language prompts, this assumption is deeply questionable. Prompt elements interact semantically: an identity framing ("You are a creative polymath") changes the meaning of a behavioral instruction ("Be precise and analytical").

**Citation:** Wright, A.H. & Zhao, J. (2008). "The Fundamental Problem with the Building Block Hypothesis." arXiv:0810.3356.

---

## 2. Crossover for Variable-Length, Non-Binary Representations

Prompts are not bit strings. They are variable-length natural language with hierarchical semantic structure. The relevant prior art comes from Genetic Programming (GP), which operates on tree structures and variable-length linear representations.

### Subtree Crossover (Standard GP)

The standard GP crossover selects a random subtree from each parent and swaps them. This is highly disruptive — offspring can differ dramatically from both parents in both syntax and semantics. Known issues:

- **Bloat**: Trees grow ~1 level per generation, leading to subquadratic bloat in program length with no corresponding fitness improvement.
- **Non-locality**: Swapped subtrees have different *contexts* in each parent. A subtree that works well in one context may be meaningless in another.

**Citation:** Koza, J.R. (1992). *Genetic Programming*. MIT Press.

### Homologous Crossover

Restricts crossover to the *same position* in both parents. Offspring inherit genetic material from structurally aligned regions. This produces "considerably reduced increases in program size (i.e., less bloat) and no detrimental effect on GP performance."

**Citation:** Langdon, W.B. & Poli, R. (2002). "Size Fair and Homologous Tree Crossovers for Tree Genetic Programming." *Genetic Programming and Evolvable Machines*, 3(1).

### Context-Preserving Crossover

D'haeseleer (1994) introduced **strong** and **weak context-preserving crossover**, which attempt to preserve the context in which subtrees appeared in the parent trees, rather than randomly selecting crossover points.

### Semantic Crossover

The most relevant line of work for prompt evolution. Rather than operating on syntax, semantic crossover operates on the *behavior* (output semantics) of programs:

- **Semantic Similarity-based Crossover (SSC)**: Selects crossover points where the swapped subtrees have similar semantic behavior, preserving the overall program semantics while introducing controlled variation. "By using semantics, the performance of Genetic Programming is enhanced both on training and testing data."

- **Geometric Semantic Crossover (SGX)**: Produces offspring whose semantics are geometrically intermediate between the parents in semantic space. The semantic distance between children and parents converges to near-zero within ~5 generations — meaning offspring behave almost identically to parents but with small, directed semantic perturbations.

**Citation:** Uy, N.Q. et al. (2010). "Improving the Generalisation Ability of Genetic Programming with Semantic Similarity Based Crossover." EuroGP 2010.
**Citation:** Moraglio, A. et al. (2012). "Geometric Semantic Genetic Programming." *PPSN XII*.

### Relevance to Prompt Crossover

The lesson from GP is clear: **naive syntactic crossover (cut-and-splice) is destructive for structured representations**. Effective crossover for prompts should be:
- **Semantically aware**: Understand what each section of a prompt *does*
- **Context-preserving**: Maintain coherence across the combined result
- **Homologous**: Recombine structurally equivalent sections (e.g., identity framing with identity framing, not identity framing with a constraint list)

---

## 3. LLM-Mediated Crossover: How the Field Does It

The key insight of modern prompt evolution is that **the LLM itself is the crossover operator**. Rather than doing literal text splicing, you *prompt the LLM to perform recombination*. This is fundamentally different from classical EA crossover — the operator has semantic understanding.

### EvoPrompt (Guo et al., 2023; ICLR 2024)

EvoPrompt implements two evolutionary strategies:

**GA-style crossover + mutation:**
The template instructs the LLM in two steps:

```
Please follow the instruction step-by-step to generate a better prompt.
1. Cross over the following prompts and generate a new prompt:
   Prompt 1: [parent1]
   Prompt 2: [parent2]
2. Mutate the prompt generated in Step 1 and generate a final prompt
   bracketed with <prompt> and </prompt>.
```

The LLM performs *semantic* crossover — it doesn't literally splice text at a midpoint. Instead, it understands both parents and generates a coherent offspring that inherits characteristics from each. The paper notes that words from Prompt 1 and Prompt 2 appear in the offspring, but they are integrated into a semantically coherent whole.

**DE-style (Differential Evolution):**
Inspired by DE's use of difference vectors, this approach:
1. Takes the current best prompt as the "base vector"
2. Selects two random prompts and identifies their *differences*
3. Mutates only the differing parts, preserving shared components (which are presumed beneficial)
4. Performs crossover by selectively replacing parts of the current best with mutated different parts

The DE approach "preserves shared components that tend to have a positive impact on performance," which is analogous to preserving building blocks.

**Results:** EvoPrompt's GA variant outperformed both human-engineered prompts and prior automatic methods by up to 25% on BBH benchmarks. The DE variant was competitive but showed different strengths depending on the task.

**Citation:** Guo, Q., Wang, R. et al. (2023). "Connecting Large Language Models with Evolutionary Algorithms Yields Powerful Prompt Optimizers." arXiv:2309.08532.

### PromptBreeder (Fernando et al., 2023; DeepMind)

PromptBreeder is primarily mutation-focused but includes a crossover mechanism:

- **Prompt Crossover**: With 10% probability after mutation, a task-prompt is replaced wholesale with a randomly chosen task-prompt from another population member (selected by fitness-proportionate selection). This is essentially *uniform crossover at the individual level* — the entire prompt is replaced, not parts of it.

- **Context Shuffling**: The few-shot exemplar context can also be recombined between individuals.

PromptBreeder's five mutation operator classes are more sophisticated:
1. **Direct Mutation**: Apply mutation-prompt to task-prompt
2. **EDA Mutation** (Estimation of Distribution): Present the LLM with a list of high-performing prompts and ask it to generate a new one "in the style of" this distribution
3. **Hypermutation**: Mutate the mutation-prompts themselves (meta-evolution)
4. **Lamarckian Mutation**: Generate improvements based on working through training examples
5. **Prompt Crossover & Context Shuffling** (described above)

The EDA mutation is particularly interesting — it's essentially a *population-level crossover* that considers multiple parents simultaneously, asking the LLM to identify patterns across successful prompts.

**Citation:** Fernando, C. et al. (2023). "Promptbreeder: Self-Referential Self-Improvement via Prompt Evolution." arXiv:2309.16797.

### MOPrompt (2025)

MOPrompt uses NSGA-II for multi-objective optimization (accuracy vs. token cost) and employs LLM-driven semantic crossover and mutation:

> "API-driven LLM calls induce semantic crossover (merging key instructions, removing redundancy) and mutation (rephrasing, shortening)."

This achieved up to 31% token reduction without compromising accuracy, demonstrating that crossover can help *compress* prompt semantics.

**Citation:** MOPrompt: Multi-objective Semantic Evolution for Prompt Optimization. arXiv:2508.01541 (2025).

### GAAPO (2025)

GAAPO allocates only 10% of operations to crossover, using a simple midpoint-split approach: "splits each prompt approximately at its midpoint and combines the first half of one prompt with the second half of the other." The authors acknowledge this is crude and suggest "semantic block identification and recombination" as future work.

**Citation:** GAAPO: Genetic Algorithmic Applied to Prompt Optimization. *Frontiers in AI*, 2025.

### Summary: What Works

| System | Crossover Type | Mechanism | Effectiveness |
|--------|---------------|-----------|---------------|
| EvoPrompt GA | LLM-mediated semantic | Two-step: cross then mutate | Strong (ICLR 2024) |
| EvoPrompt DE | Difference-preserving | Preserve shared, mutate different | Competitive |
| PromptBreeder | Wholesale replacement (10%) | Replace entire prompt | Minor role |
| MOPrompt | LLM semantic merge | Merge instructions, remove redundancy | Strong for compression |
| GAAPO | Midpoint text splice | Naive cut-and-splice | Acknowledged as crude |

The clear winner is **LLM-mediated semantic crossover** — using the LLM itself to understand and recombine parent prompts, rather than performing literal text operations.

---

## 4. Crossover vs. Mutation: What Actually Helps?

### The "Crossover Is Useless" Camp

**Fogel and Chellapilla** argued through Evolutionary Programming (EP) that crossover is unnecessary — mutation alone is sufficient. EP deliberately omits crossover, treating each individual as a separate species. Their work on evolving neural networks for checkers demonstrated strong performance with mutation only.

A rigorous empirical study found: "Crossover does not significantly outperform mutation on most of the problems examined" across six standard GP benchmarks (Luke & Spector, 2008).

A comparative analysis across nine GA techniques and four combinatorial optimization problems found: "All GA techniques that prioritize the use of blind crossover operators are outperformed by the technique that gives more importance to the mutation phase." Blind crossover "helps a broad exploration of the solution space but does not help to make an exhaustive search of promising regions."

**Citation:** Fogel, D.B. (1995). "A Comparison of Evolutionary Programming and Genetic Algorithms on Selected Constrained Optimization Problems." *Simulation*, 64(6).
**Citation:** Luke, S. & Spector, L. (2008). "A Rigorous Evaluation of Crossover and Mutation in Genetic Programming." GECCO 2008.

### The "Crossover Is Essential" Camp

**Doerr et al. (2008)** proved that for the all-pairs shortest path problem, a GA with crossover solves the problem in O(n^3.5+epsilon) expected time, while mutation-only needs Omega(n^4). This was the first proof that crossover provides a provable speedup on a non-artificial problem.

Further theoretical work showed crossover is provably essential for specific problem classes, particularly those where the solution is composed of independent components that can be discovered separately and assembled.

**Citation:** Doerr, B., Happ, E. & Klein, C. (2008). "Crossover can provably be useful in evolutionary computation." GECCO 2008.

### The Nuanced View (Current Consensus)

The current consensus is:

1. **Blind/random crossover on complex representations is often harmful** — it disrupts more than it combines.
2. **Informed/semantic crossover can be powerful** when it respects the structure of the solution space.
3. **The relative importance depends on the fitness landscape** — crossover helps most when the solution is decomposable into semi-independent building blocks.
4. **For natural language prompts specifically**, the LLM-mediated approach sidesteps the traditional debate entirely. The LLM understands the semantics, so its "crossover" is inherently *informed* rather than blind.

### Implications for Claude Resonance

The mutation-only approach (current Researcher design) may be leaving value on the table, but **only if crossover is implemented semantically, not syntactically**. Given that our "genome" is natural language and our crossover operator is an LLM, we are in the "informed crossover" regime where the empirical evidence is favorable.

---

## 5. Mate Selection: Who You Cross Matters

### Tournament Selection

The most popular selection method. Random subsets of the population are selected, and the fittest individual in each subset becomes a parent. Tournament size controls selection pressure — larger tournaments favor elites more strongly.

### Fitness-Proportionate (Roulette Wheel)

Used by EvoPrompt's GA variant. Probability of selection is proportional to fitness. Suffers from premature convergence if one individual dominates.

### Dissimilar Parent Selection (Outbreeding)

Research on **diverse partner selection** shows: "Crossover between two behaviourally diverse parents increases the probability of children being better than their parents, exploiting the relative phenotype strengths and weaknesses of pairs of parents."

**Dissortative mating** (crossing dissimilar individuals) was found to be "a robust and promising strategy for dynamic problems" and helps prevent premature convergence.

Conversely, inbreeding (crossing similar individuals) "reduces the diversity of the population" and accelerates convergence, which can be desirable late in evolution but harmful early on.

**Citation:** Trujillo, L. et al. (2018). "Diverse partner selection with brood recombination in genetic programming." *Applied Soft Computing*.
**Citation:** Fernandes, C.M. et al. (2005). "Assortative Mating in Genetic Algorithms for Dynamic Problems." *Adaptive and Natural Computing Algorithms*.

### Novelty-Based and Quality-Diversity Selection

**MAP-Elites** and related Quality-Diversity algorithms maintain a diverse archive indexed by behavioral characteristics. Rather than selecting mates purely by fitness, they optimize for *both* quality and diversity simultaneously.

For prompt evolution, this suggests maintaining a diverse archive of prompts that differ along meaningful behavioral dimensions (e.g., tone, structure, instruction style), not just selecting the top-N by score.

**Citation:** Mouret, J.-B. & Clune, J. (2015). "Illuminating search spaces by mapping elites." arXiv:1504.04909.

### Implications for Mate Selection in Claude Resonance

Crossing the top-2 prompts by score is likely to produce only incremental improvement (inbreeding). Instead:
- **Cross a high-scorer with a structurally different prompt** that excels on different dimensions
- **Use dimension-specific strengths** to guide mate selection (e.g., one parent strong on "creative_surprise", the other on "specificity")
- **Maintain behavioral diversity** in the population, not just fitness diversity

---

## 6. Crossover Granularity for System Prompts

System prompts have identifiable semantic structure. A typical Claude Resonance prompt might contain:

1. **Identity framing**: "You are a..." — establishes the persona
2. **Behavioral instructions**: "When responding, always..." — guides response style
3. **Quality emphasis**: "Prioritize depth over breadth..." — sets quality criteria
4. **Meta-cognitive cues**: "Before answering, consider..." — encourages reflection
5. **Constraints**: "Keep responses under..." — sets boundaries
6. **Interaction style**: "Engage with the user's actual intent..." — shapes dialogue

### Granularity Options

**Sentence-level crossover**: Too fine-grained. Individual sentences interact heavily with their surrounding context. Splicing a sentence from one prompt into another almost always breaks coherence.

**Paragraph-level crossover**: Better, but still risks creating Frankenstein prompts where paragraphs from different design philosophies clash. E.g., combining a "be concise and direct" paragraph with a "explore ideas at length" paragraph.

**Semantic-concept-level crossover**: The right granularity. Treat each of the ~6 semantic components above as a "building block." Cross by taking the identity framing from Parent A and the meta-cognitive cues from Parent B, etc. This maps well onto the Building Block Hypothesis — each semantic component is a schema with low defining length (it's contiguous) and meaningful independent fitness contribution.

### The Right Approach

Since the LLM is the crossover operator, the best approach is to **make the semantic structure explicit** in the crossover prompt. Rather than saying "cross over these two prompts," say "here are two system prompts, each with identifiable components — recombine the strongest components from each into a coherent new prompt."

---

## 7. Recommendations for Claude Resonance

### Should We Add Crossover?

**Yes**, but with important caveats:

1. The current mutation-only approach via the Researcher is already doing *implicit* crossover — the Researcher sees multiple parent prompts and synthesizes a new one. This is analogous to PromptBreeder's EDA mutation (estimation of distribution). What's missing is *explicit, targeted recombination* of specific components from specific parents.

2. The empirical evidence favors LLM-mediated semantic crossover over blind textual crossover. Since we already have an LLM as our operator, we are well-positioned.

3. Crossover should complement, not replace, the current mutation approach. Based on GAAPO's allocation (10% crossover) and PromptBreeder's (10% crossover probability), crossover should be a *minority operation* — perhaps 20-30% of new variants in Claude Resonance.

### Implementation Design

#### A. Semantic Component Crossover

The primary crossover operator. Given two parent prompts, decompose them into semantic components and recombine:

```
You are a prompt researcher performing crossover between two parent system prompts.

## Parent A (Score: {score_a})
```
{parent_a_prompt}
```

### Parent A's strengths:
{dimension_scores_a}

## Parent B (Score: {score_b})
```
{parent_b_prompt}
```

### Parent B's strengths:
{dimension_scores_b}

## Instructions

1. Identify the semantic components in each parent:
   - Identity framing (who Claude is)
   - Behavioral instructions (how to respond)
   - Quality emphasis (what to optimize for)
   - Meta-cognitive cues (how to think)
   - Constraints (boundaries and limits)
   - Interaction style (how to engage)

2. For each component, select the stronger version based on the dimension
   scores. Parent A may be stronger on creative engagement while Parent B
   excels at specificity — combine accordingly.

3. Synthesize a new system prompt that coherently integrates the selected
   components. Do NOT simply concatenate — the components must flow naturally
   and reinforce each other.

4. Explain which components you drew from each parent and why.

Return your result as JSON with fields: system_prompt, hypothesis,
rationale, components_from_a, components_from_b.
```

#### B. Differential Crossover (EvoPrompt DE-style)

For prompts that share substantial common structure, preserve what's shared and vary what differs:

```
You are a prompt researcher evolving system prompts through differential variation.

## Base prompt (current best, score: {score_base}):
```
{base_prompt}
```

## Donor 1 (score: {score_d1}):
```
{donor1_prompt}
```

## Donor 2 (score: {score_d2}):
```
{donor2_prompt}
```

## Instructions

1. Identify what Donor 1 and Donor 2 have in common — these are likely
   robust patterns worth preserving.
2. Identify where they differ — these are the experimental "difference vector."
3. Apply the interesting differences to the Base prompt, modifying only
   the aspects that the donors suggest could vary, while preserving the
   Base prompt's proven strengths.
4. The result should be a small, targeted modification of the Base prompt,
   not a wholesale rewrite.

Return your result as JSON with fields: system_prompt, hypothesis,
rationale, preserved_elements, modified_elements.
```

#### C. EDA-Style Population Crossover

Periodically (every 3-5 generations), present the LLM with the full top-N population and ask it to identify patterns and synthesize:

```
You are a prompt researcher analyzing the population of evolved system prompts.

## Top {n} prompts from the current population:
{for each: prompt text, score, per-dimension scores}

## Instructions

1. What patterns appear in the highest-scoring prompts?
2. What's present in high scorers but absent from lower scorers?
3. What hypotheses can you form about the "ideal" system prompt?
4. Synthesize a new prompt that captures the best patterns from across
   the population, while adding your own hypothesis about what might
   push performance further.

Return your result as JSON with fields: system_prompt, hypothesis,
rationale, patterns_identified.
```

(Note: The current Researcher already does something close to this. The value-add of making it explicit as a distinct "EDA crossover" operation is in framing and emphasis.)

### Mate Selection Strategy

Implement **dimension-complementary selection**:

1. For each prompt in the population, compute a "profile" vector of per-dimension scores.
2. Select Parent A as a top performer overall.
3. Select Parent B as the prompt whose dimension profile is most *complementary* to Parent A — strong where A is weak.
4. This ensures crossover has the maximum potential to combine strengths.

Example in the existing codebase: the `_computeDimensionAverages` method in `researcher.dart` already computes per-dimension scores. Extend this to select complementary parents rather than just top-N by overall score.

### Population Management

Currently, Claude Resonance generates one variant per generation (pure mutation). To support crossover:

1. **Increase population size**: Generate 2-3 variants per generation (e.g., 1 mutation + 1 crossover, or 1 mutation + 1 semantic crossover + 1 DE crossover).
2. **Maintain diversity**: Don't just keep top-N. Use a simplified MAP-Elites approach — keep the best prompt for each "profile type" (e.g., best creative prompt, best analytical prompt, best balanced prompt).
3. **Track lineage**: The existing `parentId` field on `PromptVariant` supports single-parent lineage. Add a `parentIds` (plural) field for crossover offspring, enabling lineage analysis.

### What NOT to Do

- **Don't do literal text splicing** (midpoint splits, sentence shuffling). GAAPO tried this and acknowledged it was crude.
- **Don't use crossover more than ~30% of the time**. Mutation should remain the primary operator. Crossover is for combining proven strengths, not exploring.
- **Don't cross very similar prompts**. This is inbreeding and produces negligible variation. Use dimension-complementary selection.
- **Don't apply crossover in generation 0-2**. You need sufficient population diversity before crossover has material to work with.

### Suggested Rollout

1. **Phase 1**: Add a `parentIds` field to `PromptVariant`. Implement the semantic component crossover prompt (Operator A above). Run it for 20% of new variants (every 5th generation, generate a crossover variant alongside the mutation variant).

2. **Phase 2**: Implement dimension-complementary mate selection. Track which crossover offspring outperform their parents vs. mutation offspring. This gives ablation data on whether crossover actually helps for *this specific* fitness landscape.

3. **Phase 3**: If crossover shows value, add DE-style differential crossover (Operator B) and EDA population crossover (Operator C). Experiment with the mix ratio.

---

## References

- Doerr, B., Happ, E. & Klein, C. (2008). "Crossover can provably be useful in evolutionary computation." GECCO 2008.
- D'haeseleer, P. (1994). "Context preserving crossover in genetic programming." IEEE World Congress on Computational Intelligence.
- Fernando, C. et al. (2023). "Promptbreeder: Self-Referential Self-Improvement via Prompt Evolution." arXiv:2309.16797.
- Fernandes, C.M. et al. (2005). "Assortative Mating in Genetic Algorithms for Dynamic Problems." *Adaptive and Natural Computing Algorithms*.
- Fogel, D.B. (1995). "A Comparison of Evolutionary Programming and Genetic Algorithms on Selected Constrained Optimization Problems." *Simulation*, 64(6).
- GAAPO (2025). "Genetic Algorithmic Applied to Prompt Optimization." *Frontiers in AI*.
- Goldberg, D.E. (1989). *Genetic Algorithms in Search, Optimization, and Machine Learning*. Addison-Wesley.
- Guo, Q., Wang, R. et al. (2023). "Connecting Large Language Models with Evolutionary Algorithms Yields Powerful Prompt Optimizers." arXiv:2309.08532. ICLR 2024.
- Holland, J.H. (1975). *Adaptation in Natural and Artificial Systems*. University of Michigan Press.
- Koza, J.R. (1992). *Genetic Programming*. MIT Press.
- Langdon, W.B. & Poli, R. (2002). "Size Fair and Homologous Tree Crossovers for Tree Genetic Programming." *Genetic Programming and Evolvable Machines*, 3(1).
- Luke, S. & Spector, L. (2008). "A Rigorous Evaluation of Crossover and Mutation in Genetic Programming." GECCO 2008.
- MOPrompt (2025). "Multi-objective Semantic Evolution for Prompt Optimization." arXiv:2508.01541.
- Moraglio, A. et al. (2012). "Geometric Semantic Genetic Programming." PPSN XII.
- Mouret, J.-B. & Clune, J. (2015). "Illuminating search spaces by mapping elites." arXiv:1504.04909.
- Thierens, D. & Bosman, P.A.N. (2011). "The Linkage Tree Genetic Algorithm." PPSN XI.
- Trujillo, L. et al. (2018). "Diverse partner selection with brood recombination in genetic programming." *Applied Soft Computing*.
- Uy, N.Q. et al. (2010). "Improving the Generalisation Ability of Genetic Programming with Semantic Similarity Based Crossover." EuroGP 2010.
- Wright, A.H. & Zhao, J. (2008). "The Fundamental Problem with the Building Block Hypothesis." arXiv:0810.3356.
