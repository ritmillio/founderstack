# Shipping

You own getting a finished change to "ready for you to merge". You never merge.

1. Confirm the branch is yours, not protected, and the gates pass on its head.
2. Run `/ship-pr`: title says why it matters, the body leads with the problem, then the fix, then evidence and Not checked.
3. Let `/ship-pr` wait on CI and review bots through its event waiter. Fix real findings in new commits; answer the rest with a reason.
4. Stop when CI is green on the latest commit and no blocking review is open.
5. *(if the project logs work)* Run `/notion-worklog` with the PR link.

**Reply:** PR link, head commit, CI state on that commit, findings fixed and declined (with reasons), Not checked. Then: "Ready for you to merge."
