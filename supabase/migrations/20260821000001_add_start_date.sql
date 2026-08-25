-- DTA-3-4: 범위 일정(시작일~종료일) 지원
--
-- Todo 의 날짜 필드가 due_date 하나뿐이라 여러 날에 걸친 일정
-- (출장·여행·휴가)을 표현할 수 없었다.
--
-- 종료일을 새로 만들지 않고 due_date 를 종료일로 재해석한다.
--   start_date IS NULL  -> 하루짜리. due_date 가 그 날 (기존 동작과 동일)
--   start_date NOT NULL -> 범위. start_date ~ due_date (양끝 포함)
--
-- 이 컬럼이 없어도 기존 기능은 정상 동작한다. 앱은 start_date 가 null 이면
-- payload 에 키 자체를 넣지 않기 때문이다
-- (supabase_datasource.dart 의 _putStartDate 참조).
-- 다만 컬럼이 없으면 **범위 일정 생성이 실패한다.**

ALTER TABLE todos ADD COLUMN IF NOT EXISTS start_date TIMESTAMPTZ;

-- 확인용:
--   SELECT column_name FROM information_schema.columns
--   WHERE table_name = 'todos' AND column_name = 'start_date';
