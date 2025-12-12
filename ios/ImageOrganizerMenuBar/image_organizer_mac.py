import os
import shutil
import argparse
from datetime import datetime

# 지원하는 RAW 확장자 목록 (필요에 따라 추가/수정)
RAW_EXTENSIONS = ('.cr2', '.cr3', '.nef', '.arw', '.orf', '.rw2', '.dng', '.pef')
JPG_EXTENSIONS = ('.jpg', '.jpeg','hiff')

def get_creation_date(filepath):
    """파일 생성 날짜/시간을 datetime 객체로 반환"""
    try:
        # macOS/Linux에서 st_ctime (Change time) 또는 st_mtime (Modification time)을 사용
        # st_birthtime (생성 시간)을 우선 시도
        timestamp = os.path.getctime(filepath)
        return datetime.fromtimestamp(timestamp)
    except Exception as e:
        print(f"Error getting date for {filepath}: {e}")
        return None

def organize_files(input_dir, args):
    """
    폴더 내 파일을 설정에 따라 정리하는 메인 함수
    """
    print(f"Start organizing files in: {input_dir}")
    
    # 설정 값 파싱
    mode = args.mode
    base_name = args.base_name if args.base_name else "이미지"
    by_extension = args.by_extension
    process_jpg = args.process_jpg
    process_raw = args.process_raw
    overwrite = args.overwrite
    date_format = args.date_format

    processed_count = 0
    file_list = [f for f in os.listdir(input_dir) if os.path.isfile(os.path.join(input_dir, f))]
    
    # 번호 부여 모드일 경우 시퀀스 시작
    sequence_num = 1
    
    for filename in sorted(file_list):
        src_path = os.path.join(input_dir, filename)
        name, ext = os.path.splitext(filename)
        ext = ext.lower()

        # 정리 대상 파일인지 확인
        is_raw = ext in RAW_EXTENSIONS
        is_jpg = ext in JPG_EXTENSIONS
        
        if not (is_raw or is_jpg) and not by_extension:
            continue  # JPG, RAW, 확장자별 정리가 모두 꺼져있다면 무시

        if not by_extension:
            if is_jpg and not process_jpg:
                continue
            if is_raw and not process_raw:
                continue

        # --- 1. 날짜 정보 가져오기 ---
        file_date = get_creation_date(src_path)

        if not file_date:
            print(f"Skipping {filename}: Could not determine date.")
            continue

        # --- 2. 대상 폴더 경로 설정 ---
        
        # 2-1. 날짜 기반 상위 폴더 (선택 사항)
        date_folder = ""
        if date_format == 1: # YYYYMM
            date_folder = file_date.strftime("%Y%m")
        elif date_format == 2: # YYYY/MM
            date_folder = os.path.join(file_date.strftime("%Y"), file_date.strftime("%m"))
        elif date_format == 3: # YYYY-MM-DD
            date_folder = file_date.strftime("%Y-%m-%d")
            
        # 2-2. 카테고리/확장자 폴더
        category_folder = ""
        if by_extension:
            category_folder = ext.upper().lstrip('.')
        elif is_jpg:
            category_folder = "JPG"
        elif is_raw:
            category_folder = "RAW"
            
        # 최종 대상 폴더 구성
        if date_folder and category_folder:
            target_folder = os.path.join(input_dir, date_folder, category_folder)
        elif date_folder:
            target_folder = os.path.join(input_dir, date_folder)
        elif category_folder:
            target_folder = os.path.join(input_dir, category_folder)
        else:
            target_folder = input_dir # 분류 옵션이 모두 꺼져있으면 현재 디렉토리 유지

        # 대상 폴더 생성
        os.makedirs(target_folder, exist_ok=True)


        # --- 3. 새 파일명 결정 ---
        new_filename = filename
        
        if mode == 2: # 번호로 파일명 부여
            new_filename = f"{base_name}_{sequence_num}{ext}"
            sequence_num += 1
            
        elif mode == 3: # 날짜로 파일명 부여
            date_str = file_date.strftime("%Y%m%d")
            new_filename = f"{base_name}_{date_str}_{sequence_num}{ext}"
            sequence_num += 1
            
        # 모드 1: 기존 파일명 유지 (new_filename = filename)

        
        # --- 4. 파일 이동 및 충돌 처리 ---
        dest_path = os.path.join(target_folder, new_filename)
        
        if os.path.exists(dest_path):
            if overwrite:
                print(f"Overwriting {dest_path}")
                os.remove(dest_path) # 덮어쓰기 허용 시 기존 파일 삭제
            else:
                # 덮어쓰기 불허 시, 파일명 뒤에 _1, _2 등을 붙여 충돌 회피
                i = 1
                temp_name, temp_ext = os.path.splitext(new_filename)
                while os.path.exists(dest_path):
                    new_filename = f"{temp_name}_{i}{temp_ext}"
                    dest_path = os.path.join(target_folder, new_filename)
                    i += 1
                print(f"Renamed {filename} to {new_filename} to avoid collision.")

        try:
            shutil.move(src_path, dest_path)
            processed_count += 1
        except Exception as e:
            print(f"Failed to move {filename} to {dest_path}: {e}")
            
    print(f"--- Organizing finished. Processed {processed_count} files. ---")

# --------------------------------------------------------------------------
# 📢 스위프트에서 넘겨주는 인수를 처리하기 위한 argparse 설정
# --------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Image Organizer for macOS")
    
    # 필수 인자
    parser.add_argument("--input_dir", required=True, type=str, help="Input directory path to organize.")
    
    # 설정 인자
    parser.add_argument("--mode", type=int, default=1, help="File naming mode (1: keep, 2: sequence, 3: date + sequence)")
    parser.add_argument("--base_name", type=str, default="이미지", help="Base name for new files.")
    
    parser.add_argument("--by_extension", type=lambda x: x.lower() == 'true', default=False, help="Organize by extension.")
    parser.add_argument("--process_jpg", type=lambda x: x.lower() == 'true', default=True, help="Process JPG files if not by_extension.")
    parser.add_argument("--process_raw", type=lambda x: x.lower() == 'true', default=True, help="Process RAW files if not by_extension.")
    
    parser.add_argument("--overwrite", type=lambda x: x.lower() == 'true', default=False, help="Allow overwriting existing files.")
    parser.add_argument("--date_format", type=int, default=0, help="Date folder format (0: none, 1: YYYYMM, 2: YYYY/MM, 3: YYYY-MM-DD)")
    
    args = parser.parse_args()
    
    # 파이썬 정리 함수 호출
    organize_files(args.input_dir, args)

if __name__ == '__main__':
    main()
