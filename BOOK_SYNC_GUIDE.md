# Book Sync Service - Setup Guide

## What Changed

Your app now automatically syncs books from your FTP server every hour. Here's how it works:

### Features:
1. **Automatic Sync**: App checks for new JSON files every hour
2. **Smart Download**: Only downloads new files that aren't already stored locally
3. **Flexible**: Just add JSON files to `/zmongolnom/js/` on your FTP server
4. **Background Service**: Runs automatically, no user action needed

### How to Use:

1. **Upload JSON Files to FTP Server**:
   - Server: v2001.coreserver.jp
   - Port: 21
   - Username: zmongol@hiimor.com
   - Password: Zm20251212
   - Directory: `/zmongolnom/js/`
   - File format: `BookName.json` (filename becomes the book identifier)

2. **JSON File Format**:
   The JSON file should contain book metadata. Example:
   ```json
   {
     "title": "ᡯᡭᢍ ᡢ ᢚᡪᢊᡬᢍ ᢘᡭᢞᡪᢑᡪᢐ",
     "author": "Author Name",
     "image": "assets/images/book1.png",
     "chapters": [
       {
         "name": "Chapter 1",
         "content": "..."
       }
     ]
   }
   ```

3. **Sync Behavior**:
   - Initial sync: When app starts
   - Automatic sync: Every 1 hour
   - Logs: Check Flutter console for sync status

### Implementation Notes:

- The service stores downloaded files locally in app documents directory
- Files are stored at: `/data/user/0/com.example.book_app/documents/books/`
- The BookCtrl can be extended to load books from local storage
- No network required after initial download (files cached locally)

### Next Steps:

1. Run `flutter pub get` to install the new `ftp_connect` package
2. Upload your JSON files to the FTP server
3. Restart the app - it will automatically download and sync books

### Troubleshooting:

- Check Flutter console for error messages
- Ensure FTP credentials are correct
- Verify JSON files are in `/zmongolnom/js/` directory
- Check that JSON filenames end with `.json`

---

**Note**: The app runs in the background, so even if you don't open it, it will still attempt to sync when the OS allows.
