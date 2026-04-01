# GitHub Save Task Progress

## Plan Steps:
- [x] Plan approved by user
- [x] Update .gitignore for temp files
- [x] Install GitHub CLI (winget)
- [ ] gh auth login
- [ ] Create repo & push: gh repo create hotline-app --public --push --source=. --remote=origin --force
- [ ] Verify remote & status clean
- [ ] flutter pub get

## Original App TODO:
# Navigation Fix: Sidebar Back to Emergency Hotline

Status: Pending

## Steps:
1. [x] Add drawer (AdminSidebar) to NewsPage in lib/news_page.dart, similar to HomePage, with navigation handler that:
   - Index 0: Navigator.pop(context) to return to home/hotline
   - Emergency item: Navigator.popUntil home, then push HotlinePage()
2. [ ] Add drawer to HotlinePage
2. [ ] Add drawer to HotlinePage in lib/hotline.dart with navigation to NewsPage
3. [ ] Update AdminSidebar (if needed) to keep Emergency Hotline item always clickable
4. [ ] Test flow: Home -> Hotline -> sidebar News -> sidebar Emergency Hotline
5. [ ] Test back button works
6. [ ] Complete task
