- [ ] 0. Create release task in ticket tracker.
- [ ] 1. Update app version.

```
    $> cd safe; agvtool new-marketing-version x.x.x;cd ..
```

- [ ] 2. Edit CHANGELOG.rst and add info about new version.
- [ ] 3. Create pull-request with these changes and merge it.
- [ ] 4. Test AdHoc version.
- [ ] 5. Release to testers or to app store
- [ ] 6. Tag the released commit and push tags

```
   $> git tag -am "x.x.x" x.x.x
   $> git push --tags
```