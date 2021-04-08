// Copyright 2021 Kwai, Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// CSS `cursor` values types. From https://developer.mozilla.org/en-US/docs/Web/CSS/cursor
enum Cursor {
  /// The UA will determine the cursor to display based on the current context. E.g., equivalent to text when hovering text.
  auto,

  // Can't name "default" (is keyword)
  /// The platform-dependent default cursor. Typically an arrow.
  defaultCursor,

  /// No cursor is rendered.
  none,

  /// A context menu is available.
  contextMenu,

  /// Help information is available.
  help,

  /// The cursor is a pointer that indicates a link. Typically an image of a pointing hand.
  pointer,

  /// The program is busy in the background, but the user can still interact with the interface (in contrast to wait).
  progress,

  /// The program is busy, and the user can't interact with the interface (in contrast to progress). Sometimes an image of an hourglass or a watch.
  wait,

  /// The table cell or set of cells can be selected.
  cell,

  /// Cross cursor, often used to indicate selection in a bitmap.
  crosshair,

  /// The text can be selected. Typically the shape of an I-beam.
  text,

  /// The vertical text can be selected. Typically the shape of a sideways I-beam.
  verticalText,

  /// An alias or shortcut is to be created.
  alias,

  /// Something is to be copied.
  copy,

  /// Something is to be moved.
  move,

  /// An item may not be dropped at the current location.
  noDrop,

  /// The requested action will not be carried out.
  notAllowed,

  /// Something can be grabbed (dragged to be moved).
  grab,

  /// Something is being grabbed (dragged to be moved).
  grabbing,

  /// Something can be scrolled in any direction (panned).
  allScroll,

  /// The item/column can be resized horizontally. Often rendered as arrows pointing left and right with a vertical bar separating them.
  colResize,

  /// The item/row can be resized vertically. Often rendered as arrows pointing up and down with a horizontal bar separating them.
  rowResize,

  /// North edge is to be moved.
  nResize,

  /// East edge is to be moved.
  eResize,

  /// South edge is to be moved.
  sResize,

  /// West edge is to be moved.
  wResize,

  /// North-east edge is to be moved.
  neResize,

  /// North-west edge is to be moved.
  nwResize,

  /// South-east edge is to be moved.
  seResize,

  /// South-west edge is to be moved.
  swResize,

  /// East-west bidirectional resize cursor.
  ewResize,

  /// North-south bidirectional resize cursor.
  nsResize,

  /// North-east to south-west bidirectional resize cursor.
  neswResize,

  /// North-west to south-east bidirectional resize cursor.
  nwseResize,

  /// Something can be zoomed (magnified) in.
  zoomIn,

  /// Something can be zoomed (magnified) out.
  zoomOut,
}

/// CSS values for cursors.
const CursorValues = <Cursor, String>{
  Cursor.auto: "auto",
  Cursor.defaultCursor: "default",
  Cursor.none: "none",
  Cursor.contextMenu: "context-menu",
  Cursor.help: "help",
  Cursor.pointer: "pointer",
  Cursor.progress: "progress",
  Cursor.wait: "wait",
  Cursor.cell: "cell",
  Cursor.crosshair: "crosshair",
  Cursor.text: "text",
  Cursor.verticalText: "vertical-text",
  Cursor.alias: "alias",
  Cursor.copy: "copy",
  Cursor.move: "move",
  Cursor.noDrop: "no-drop",
  Cursor.notAllowed: "not-allowed",
  Cursor.grab: "grab",
  Cursor.grabbing: "grabbing",
  Cursor.allScroll: "all-scroll",
  Cursor.colResize: "col-resize",
  Cursor.rowResize: "row-resize",
  Cursor.nResize: "n-resize",
  Cursor.eResize: "e-resize",
  Cursor.sResize: "s-resize",
  Cursor.wResize: "w-resize",
  Cursor.neResize: "ne-resize",
  Cursor.nwResize: "nw-resize",
  Cursor.seResize: "se-resize",
  Cursor.swResize: "sw-resize",
  Cursor.ewResize: "ew-resize",
  Cursor.nsResize: "ns-resize",
  Cursor.neswResize: "nesw-resize",
  Cursor.nwseResize: "nwse-resize",
  Cursor.zoomIn: "zoom-in",
  Cursor.zoomOut: "zoom-out",
};
