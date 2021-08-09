@obj
external makeProps: (
  ~children: React.element,
  ~title: React.element,
  ~placement: string,
  ~arrow: bool,
  ~leaveDelay: int,
  ~enterTouchDelay: int,
  ~leaveTouchDelay: int,
  unit,
) => _ = ""

@module("@material-ui/core")
external make: React.component<{
  "children": React.element,
  "title": React.element,
  "placement": string,
  "arrow": bool,
  "leaveDelay": int,
  "enterTouchDelay": int,
  "leaveTouchDelay": int,
}> = "Tooltip"