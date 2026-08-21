-- DTA-3-1: Google Calendar 동기화 중복 방지
--
-- 할 일을 Google Calendar 에 등록하면 그 이벤트 ID 를 여기에 보관한다.
-- 다음 동기화 때 값이 있으면 새로 만들지 않고 기존 이벤트를 갱신하므로
-- 같은 일정이 중복 등록되지 않는다.
--
-- 이 컬럼이 없어도 앱은 정상 동작한다. 앱은 이 값을 일반 UPDATE payload 에
-- 넣지 않고 전용 경로로만 쓰기 때문이다(supabase_datasource.updateGoogleEventId).
-- 다만 컬럼이 없으면 ID 저장이 매번 실패해 **중복 방지가 동작하지 않는다.**

ALTER TABLE todos ADD COLUMN IF NOT EXISTS google_event_id TEXT;

-- 확인용:
--   SELECT column_name FROM information_schema.columns
--   WHERE table_name = 'todos' AND column_name = 'google_event_id';
