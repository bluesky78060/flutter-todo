# Tasks - Todo App Development

## 2025-11-25 (Monday)

### ✅ Completed Tasks

#### 1. Attachment System Implementation (첨부파일 시스템 구현)
**Status**: Fully Implemented ✅
**Priority**: 🟡 Medium

**Implemented Features**:
- ✅ Supabase Storage setup with `todo-attachments` bucket
- ✅ Row-Level Security (RLS) policies for file access control
- ✅ File upload/download functionality (images, PDFs, text files, JSON, etc.)
- ✅ File picker integration (camera, gallery, file system)
- ✅ Image viewer with zoom and pan (InteractiveViewer)
- ✅ PDF viewer with Syncfusion PDF Viewer (zoom, text selection)
- ✅ Text file viewer supporting 40+ file extensions
- ✅ JSON file upload support (MIME type mapping workaround)
- ✅ Attachment metadata storage (local Drift + remote Supabase)
- ✅ Attachment display in todo detail screen (grid view with icons)
- ✅ File size formatting and display
- ✅ **Automatic attachment deletion when todo is deleted**

**Files Created**:
- `lib/domain/entities/attachment.dart` - Freezed immutable entity
- `lib/domain/repositories/attachment_repository.dart` - Repository interface
- `lib/data/datasources/local/drift_attachment_datasource.dart` - Local DB operations
- `lib/data/datasources/remote/supabase_attachment_datasource.dart` - Remote DB operations
- `lib/data/repositories/attachment_repository_impl.dart` - Local repository implementation
- `lib/data/repositories/supabase_attachment_repository.dart` - Remote repository implementation
- `lib/core/services/attachment_service.dart` - File upload/download service
- `lib/presentation/providers/attachment_providers.dart` - Riverpod providers
- `lib/presentation/widgets/image_viewer_dialog.dart` - Image viewer UI
- `lib/presentation/widgets/pdf_viewer_dialog.dart` - PDF viewer UI
- `lib/presentation/widgets/text_viewer_dialog.dart` - Text file viewer UI
- `SUPABASE_STORAGE_SETUP.md` - Setup documentation

**Files Modified**:
- `lib/data/datasources/local/app_database.dart` - Added attachments table
- `lib/presentation/screens/todo_detail_screen.dart` - Added attachments section
- `lib/presentation/widgets/todo_form_dialog.dart` - Added file picker UI
- `lib/presentation/providers/todo_providers.dart` - Added attachment deletion on todo delete
- `assets/translations/ko.json` - Added attachment-related translation keys
- `pubspec.yaml` - Added dependencies: `syncfusion_flutter_pdfviewer: ^28.2.7`

**Technical Decisions**:
1. **Dual Repository Pattern**: Local (Drift) + Remote (Supabase) for offline support
2. **Storage Path Structure**: `{userId}/{todoId}/{timestamp}_{filename}` for organization
3. **MIME Type Mapping**: JSON files mapped to `text/plain` to bypass Supabase restrictions
4. **Viewer Strategy**:
   - Images: InteractiveViewer for pinch-to-zoom
   - PDFs: Syncfusion PDF Viewer for professional rendering
   - Text files: SelectableText with monospace font for 40+ extensions
5. **Cascade Deletion**: Todo deletion triggers automatic Storage file cleanup

**Testing**:
- ✅ File upload (camera, gallery, file picker)
- ✅ File viewer (images, PDFs, text files, JSON)
- ✅ MIME type handling (JSON workaround verified)
- ✅ **Attachment deletion on todo delete (Supabase Storage cleanup)**

**Supabase Configuration**:
```sql
-- Storage bucket: todo-attachments
-- RLS enabled with user isolation policies
-- attachments table with foreign key cascade delete
```

**Known Limitations**:
- Mobile-only file upload (web support requires additional work)
- No file size limit enforcement yet (recommended: 10MB per file)
- No attachment count limit (recommended: 5-10 per todo)

**Next Steps** (Future Enhancements):
- [ ] Add file size validation
- [ ] Implement attachment count limits
- [ ] Add web file upload support
- [ ] Add attachment download button
- [ ] Add attachment deletion UI (individual files)
- [ ] Add video viewer
- [ ] Add audio player for audio files

---

## Previous Sessions

### 2025-11-18 to 2025-11-24
See `FUTURE_TASKS.md` and `RELEASE_NOTES.md` for detailed history of:
- Drag & drop todo reordering (1.0.13+39)
- Admin dashboard with anonymized statistics
- Google Play upload key reset
- Flutter Web OAuth fixes
- Naver Maps integration
- Location-based todos (Phase 1-3)
- Subtasks feature
- Snooze functionality
- CI/CD pipeline setup

---

## Documentation References

- **Setup Guide**: `SUPABASE_STORAGE_SETUP.md`
- **Future Tasks**: `FUTURE_TASKS.md`
- **Release Notes**: `RELEASE_NOTES.md`
- **Main Documentation**: `CLAUDE.md`

---

**Last Updated**: 2025-11-25 21:15 KST
