# 📂 Image Organizer

드래그 앤 드롭 기반의 이미지 정리 도구입니다.  
확장자 또는 날짜 기준으로 JPG/RAW 파일을 자동 분류하고,  
파일명을 유지하거나 일련번호 또는 촬영일자로 재정렬할 수 있습니다.

![UI](https://github.com/duaghwns/image_organizer/image_organizer.png)

## 🔧 주요 기능

- ✅ JPG, RAW 파일 자동 정리 (.JPG, .CR3 등)
- ✅ 확장자별 정리 or 날짜 기반 폴더 정리
- ✅ 파일명: 유지 / 일련번호 / 날짜 기반 지정
- ✅ 날짜 폴더: `YYYYMM`, `YYYY/MM`, `YYYY-MM-DD` 포맷 지원
- ✅ 덮어쓰기 허용 옵션
- ✅ 진행률 표시

## 🖥️ 실행 방법

Python 3.8 이상이 필요합니다.

```bash
pip install pillow tkinterdnd2
python image_organizer.py
