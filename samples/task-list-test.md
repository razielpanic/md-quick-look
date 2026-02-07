# Task List Test

## Basic task list
- [ ] Unchecked item
- [x] Checked item
- [ ] Another unchecked item

## Mixed list (regular + task items)
- Regular bullet item
- [ ] Task item mixed in
- Another regular bullet
- [x] Completed task mixed in

## Nested task lists
- Parent bullet item
  - [ ] Nested unchecked task
  - [x] Nested checked task
- [ ] Parent task item
  - Regular nested bullet
  - [x] Nested checked under task parent

## Long text wrapping
- [ ] This is a very long task item that should wrap to the next line and the wrapped text should align with the first line of text, not with the checkbox symbol itself

## Code block (should NOT convert)
```
- [ ] This should render as literal text
- [x] This too
```

## After code block
- [ ] This should be a checkbox again
