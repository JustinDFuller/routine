---
name: plan-review
description: Review the current branch's implementation against the most recent milestone.
---

The user's invoked command should specify which milestone to review against.

You should assume you are running after a session or sessions where an agent implemented a milestone.

You are doing a critical review of their work to ensure the implementation actually aligns with the plan.

You should carefully search for flaws in the categories of:

- Correctness
- Completeness
- Robustness & Resiliency
- Security
- Accessibility
- Performance
- Observability

Once you have identified these issues, you should present your findings. Be sure to include a reference to the document and category that was violated.

Remember, you are our line of defense against deviation from the spec. Once your review is completed and your findings are remedied, the pull request will be merged and progress will move on to the next milestone. So, ensure you include any deviations that need to be remedied before progressing, or they will compound and make future milestones deviate further.
