#include "svdpi.h"
#include "dpiheader.h"

#include <windows.h>
#include <string>

union ulong_char {
    char c[8];
    unsigned long long ul;
    int i;
};

/*
"top1: init"
"top2: write64"
"top3: read64"
"top4: vwait"
"top5: finish"
*/

DPI_LINK_DECL
int c_tb() {
  volatile char *buf;
  HANDLE map_handle;
  HANDLE handle;
  int size;
  std::wstring fname;

  fname.append(L"tb.txt");
  handle = CreateFileW(fname.c_str(), GENERIC_READ|GENERIC_WRITE, FILE_SHARE_READ|FILE_SHARE_WRITE, 0,
                      OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
  if(handle == INVALID_HANDLE_VALUE) {
    //fprintf(stderr, "file open failed\n");
    exit(1);
  }
  size = GetFileSize(handle, 0);
  map_handle = CreateFileMapping(handle, 0, PAGE_READWRITE, 0, 0, 0);
  buf = (char*)MapViewOfFile(map_handle, FILE_MAP_ALL_ACCESS, 0, 0, 0);
  if(handle != INVALID_HANDLE_VALUE) {
    CloseHandle(handle);
    handle = INVALID_HANDLE_VALUE;
  }

  while(1){
    if(buf[0] != 0){
      if(buf[0] == 1){
        v_init();
      }
      else if(buf[0] == 2){
        union ulong_char address, data;
        for(int i=0; i<8; i++){
          address.c[i] = buf[i+8];
          data.c[i] = buf[i+16];
        }
        v_write64(address.i, data.ul);
      }
      else if(buf[0] == 3){
        union ulong_char address, data;
        for(int i=0; i<8; i++){
          address.c[i] = buf[i+8];
        }
        v_read64(address.i, &data.ul);
        for(int i=0; i<8; i++){
          buf[i+16] = data.c[i];
        }
      }
      else if(buf[0] == 4){
        union ulong_char times;
        for(int i=0; i<8; i++){
          times.c[i] = buf[i+8];
        }
        v_wait(times.i);
      }
      else if(buf[0] == 5){
        buf[0] = 0;
        break;
      }
      buf[0] = 0;
    }
  }

  UnmapViewOfFile((char*)buf);
  if(map_handle != INVALID_HANDLE_VALUE) {
    CloseHandle(map_handle);
    map_handle = INVALID_HANDLE_VALUE;
  }

  return 0;
}
