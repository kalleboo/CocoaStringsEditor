CocoaStringsEditor
==================

Bulk-edits multiple languages of Localizable.strings files in Cocoa projects

What you can do:
* Open a .strings file inside an .lproj directory
* It finds the corresponding strings files in any other .lproj directories in the same parent dir
* You can then edit existing strings in all languages from one view.
* You can mass copy/paste strings (in all associated languages) between .strings files
* Changes can then be saved to all the files at once.

The good:
* Reads well-formed .strings files
* Writes .strings files
* TableView editor
* Auto-detects languages
* Edits multiple languages at once
* Copy/Paste of multiple rows
* Revert works

The bad / TODO:
* Naive parser.
 * Will NSAssert() and bail out when its naive string-matching expectations aren't met.
 * Will ignore certain errors and only log to console (missing comments, duplicate keys)
* Does no escaping or unescaping of strings, so you'll have to do that while editing.
* Can't add or remove rows
* Can't edit keys or comments
* No drag/drop
* Copy/Paste only works with custom JSON (can't copy/paste in the native .strings format)
* Basic tableview editor - no multiline or anything fancy like that
* No working "Save As..."

Pull requests gladly accepted!