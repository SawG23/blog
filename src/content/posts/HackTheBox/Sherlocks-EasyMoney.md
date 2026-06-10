---
title: "HackTheBox - Sherlocks - Easy Money"
description: "HackTheBox Sherlock challenge"
published: 2026-04-13
tags: ["HackTheBox","CVE-2024-6473","DFIR"]
category: "CTF - writeup"
draft: false
---


![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/B12Wgvv2Wl.png)
Đây là một challenge thuộc HackTheBox Sherlocks. Description của đề:

> John is an employee at a mid-sized tech company. He works as a Senior IT support specialist, but his true passion is finding ways to make extra money. John is always on the lookout for giveaways, discounts, and any opportunity to earn a quick buck. He’s not particularly tech-savvy when it comes to cybersecurity, but he’s resourceful and knows how to follow online tutorials.
> 
> Recently, John came across an enticing giveaway that promised exciting rewards. However, when he opened the giveaway, he didn’t find or win anything. This made him suspicious that something might have gone wrong with his machine. Concerned about the unusual behavior, John has reached out to you, the investigator, to uncover what happened and whether his system has been compromised.

Phân tích context của đề một tí, thì chúng ta biết được rằng có vẻ nạn nhân đã bị phishing, hoặc vô tình kích hoạt mã độc khi mở file giveaway, dẫn đến máy của anh ta đã bị compromised. Oke bắt đầu tải attachment và giải quyết thoi

Attachment của đề cho ta được một thư mục evidence chứa ổ C đã được dump các artifact quan trọng thực trong việc hỗ trợ Forensics. Chúng ta tiến thành add evidence vào FTK Imager.

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/rJEewvD2Wg.png)

Trong context của đề, chúng ta biết được rằng victim đã dính phải mã độc sau khi mở file giveaway gì đấy, vậy nên lịch duyệt web là ứng cử sáng giá để bắt đầu. Trong bài này, victim dùng Edge browser nên lịch sử duyệt web sẽ nằm ở đường dẫn 
`C:\Users\{user}\AppData\Local\Microsoft\Edge\User Data\Default\*`

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/BklNYPwhbl.png)

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/HyQ19DvhZe.png)

Vì file này là file `SQLite3` nên chúng ta sẽ dùng DB Browser để mở file `History` này

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/B1IjiPv2Ze.png)

Ở đây chỉ thấy victim search rất nhiều chủ đề về giveaway và download `Yadex Browser` và file `Ultimate-Guide-to-Running-Giveaways.pdf`, cũng không thấy có gì đáng ngờ.

tiếp theo xử dụng các tool của Zimmerman mở các artifact như file `Journal ($J)`, `prefetch`, `$MFT`...
> Với những bạn chưa biết, thì:
> 
> file `$J` được coi như là cuốn nhật ký của mọi file trên phân vùng NTFS. Nó ghi lại mọi biến đổi của của file/folder (Create, Delete, Rename,...) kèm theo mốc thời gian chính xác. Nó là một trong những artifact quan trọng phục vụ cho việc Forensics của chúng ta. Vị trí `C:\$Extend\$J`.
> 
> Ngoài ra chúng ta còn một artifact rất quan trọng khác là `Prefetch`. Cơ chế là Windows sẽ tạo ra các file Prefetch (.pf) để ghi nhớ các dữ liệu mà một ứng dụng cần khi khởi động, giúp lần mở sau nhanh hơn. Từ đó nó được dùng để `chứng minh một ứng dụng đã từng được thực thi trên hệ thống hay chưa`. Vị trí `C:\Windows\Prefetch`

dùng `MFTECmd.exe` để dump `$J` ra dạng file .csv
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/H1J3buvnWg.png)

`$MFT`
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/BJgTzuvh-l.png)

`Prefetch`
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/By8YQ_vhbl.png)

Đã dump xong artifact quan trọng rồi, giờ dùng `TimelineExplorer.exe` để mở các thằng file này

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/SyqAudD3-g.png)

oke, giờ chúng ta quay lại với các câu hỏi của bài

### Task 1: At what exact time did the user execute the malicious shortcut file?
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/ry9b9_P2bg.png)

Thì mình đã tìm những file trong thư mục evidence mà đề cho chúng ta, thì có vẻ các file malicious đã bị xóa hoặc author không cung cấp cho chúng ta
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/Skc9sdw3-l.png)
> Thư mục user Administrator không có gì cả

Nên buộc chúng ta phải dựa vào các artifact của hệ thống, mà ta đã dump ở trên

thì như context đã đề cập là có liên quan đến `giveaway`, ở artifact `$J` mình tìm thấy các file `.lnk` đáng ngờ

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/HyfepOvhWl.png)

Ở mốc thời gian `2025-01-26 16:17:11` ta thấy được file `2025-GiveAways.lnk` đã được ghi xuống

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/S1AUbYD3We.png)

Dựa vào $MFT chúng ta cũng chứng minh được file đã được ghi xuống hệ thống.

Nhưng `2025-01-26 16:17:11` chỉ là thời gian file .lnk này xuất hiện. Còn đề hỏi chúng ta là thời gian execute. Vì thế chúng ta sẽ dựa vào Prefetch.

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/B1pHmYw3-e.png)

trong khoản mốc thời gian này Prefetch ghi nhận tiến trình `CONHOST.EXE` và `POWERSHELL.EXE`. Giả thiết là khi file được ghi ra vào `2025-01-26 16:17:11` thì sau đó 4 giây đã được user thực thi.



Đáp án: `2025-01-26 16:17:15`

### Task 2: The previous malicious file executed an initial payload. What is the full path of this payload?

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/S1gcLSKw3-l.png)

Để biết cụ thể powershell được đề cập ở `Task 1` đã thực thi lệnh gì, chúng ta dựa vào log `Powershell.evtx`

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/SyKkiKP3-l.png)

Có thể thấy powershell được thực thi để tải mã độc từ `https://github.com/M4shl3/okiii/raw/main/svchost.exe` sau đó ghi xuống `Temp` với tên là `svch0st.exe` sau đó thực thi, và xóa mã độc


![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/Bk5g8FDh-e.png)

Đáp án: `C:\temp\svch0st.exe`

### Task 3: At what timestamp did the payload execute and grant the attacker shell access?

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/rkM6UtDnbl.png)

Trong phân tích `Task 2`, thì ta cũng có câu trả lời cho task này.

Đáp án: `2025-01-26 16:17:54`

### Task 4: What is the command line the attacker used to enumerate installed packages on the system?

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/SJpVKKP2-x.png)

Ở câu hỏi này, chúng ta cũng vẫn dựa vào log `Powershell.evtx`
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/Hyhck9Dh-l.png)

đáp án: `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -Command Get-Package`

### Task 5: Which application did the attacker identify as vulnerable?

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/rJPlzcv3Ze.png)

Sau khi có được shell lúc `2025-01-26 16:17:54` attacker đã thực hiện các hành vi `reconnaisance` thông qua các lệnh như `whoami`, `systeminfo`, `powershell.exe -Command Get-Package`, ... thì sau đó chúng ta thấy được việc thực thi liên tiếp nhiều tiến trình BROWSER.EXE và SERVICE_UPDATE.EXE trong cùng 1-2 giây thường cho thấy hành vi exploit của attacker

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/H1hqzcDnWl.png)

Đáp án: `YandexBrowser`

### Task 6: What version of that vulnerable application did the attacker identify?

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/B1D6QqwnZl.png)

Dựa vào path của Yadex Browser ta cũng đã biết được phiên bản

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/BJXlE5Pnbe.png)

đáp án: `24.4.5.498`

### Task 7: What is the CVE associated with this vulnerability?

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/BJ4cN9v2We.png)

Khi đã có phiên bản rồi, thì việc tìm CVE khá là đơn giản

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/r1AmH9PhWx.png)

Tóm tắt về CCVE-2024-6473, thì đây là lỗ hổng `DLL Hijacking Vulnerability` vì sử dụng untrusted search path, hậu quả là mã độc có thể chạy dưới tiến trình của Yandex Browser.

### Task 8: What is the name of the legitimate binary that the attacker used to deliver the malicious payload and establish persistence on the compromised system?

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/rysZTQKnZl.png)

Khi nhắc đến các công cụ `legitimate binary` bị attacker lạm dụng thì chúng ta sẽ nghĩ nay đến `LOLBins` (Living off the Land Binaries)
> Dành cho bạn nào chưa biết LOLBins là gì:
> https://medium.com/@MonlesYen/living-off-the-land-how-attackers-abuse-lolbins-and-how-to-stop-them-078cf7e798af

Lần theo các tiến trình được chạy trong khoảng thời gian bị tấn công, chúng ta có thể thấy là `certutil.exe` đã được sử dụng trong khoảng thời gian này. Thì `certutil.exe` là một trong những công cụ `lolbins` rất hay được attacker lạm dụng để tải xuống các file mã độc. 
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/BJURAXY3Zg.png)

> Các bạn có thể tìm hiểu thêm:
> https://lolbas-project.github.io/lolbas/Binaries/Certutil/
> https://www.cybertriage.com/blog/dfir-breakdown-using-certutil-to-download-attack-tools/

Đại khái thì `certutil` có tính năng `Certificate Revocation List` (CRL) checking bằng cách tải chúng từ URL. Attacker lợi dụng tham số `-urlcache` để tải mã độc từ máy chủ C2. Từ đó vượt qua các policy bảo mật nghiêm ngặt của mạng nội bộ (Proxy/Firewall) vốn thường mở đường cho các yêu cầu liên quan đến cập nhật và xác thực chứng chỉ hệ thống.

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/H1WeQNY3Wl.png)

Đáp án: `certutil.exe`

### Task 9: What is the name of the malicious Portable Executable (PE) file that enabled him to accomplish his objective?
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/SyNQBEYnWg.png)

File PE đang được nhắc đến chính là file đã được tải xuống thông qua việc lạm dụng `certutil.exe` mà chúng ta đã bàn ở trên.

Trong blog mà mình đề cập ở trên có cung cấp các artifacts của **certutil** này.
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/BJRIU4Knbe.png)

Oke bắt đầu kiểm tra `C/Users/Administrator/AppData/LocalLow/Microsoft/CryptnetUrlCache`

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/rJoSvEK2Wx.png)

Rõ ràng nó rất sus luôn, tự nhiên thư mục chứa các cert của hệ thống thì lòi ra 1 thằng PE:)))

cat file `MetaData` của thằng này là chúng ta sẽ biết được tên của nó.

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/Bk9954Khbx.png)

đáp án: `wldp.dll`

### Task 10: What is the SHA-256 hash of that malicious file?

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/S12Bj4Y2We.png)

Tiếp theo là tính sha256 hash thoi, khá đơn giản

đáp án: `a1a17ebd90610d808e761811d17da3143f3de0d4cc5ee92bd66000dca87d9270`

### Task 11: How many milliseconds of cumulative coded sleep delays occurred before the C2 binary provided a shell after the vulnerable application was launched?

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/rJoPZBth-x.png)


Bắt đầu từ câu này thì chúng ta cần phải `reverse engineering` con malware này.

Load vào ida
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/H1z00NKh-g.png)

đề hỏi chúng ta thời gian `sleep delays` nên chúng ta sẽ bắt đầu check các thư viện được import 

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/Bk4TkHK3Ze.png)

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/HJQ0yrFn-g.png)

chúng ta thấy nó được hàm `sub_1800748E0()` gọi 2 lần

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/Hy9NZSYnZl.png)

Tính tổng của 2 thằng này
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/HJhY-BF3-e.png)

Đáp án: `11000`

### Task 12: What is the mutex name used to ensure only one instance of the C2 binary runs at a time?

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/HyDdMSYnbe.png)

Trong hàm `sub_1800748E0()` đang gọi `CreateMutexW`
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/ByljGHYnWl.png)
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/BJYOXSt2Zg.png)

Mã độc tạo ra một Mutex có tên duy nhất là `Global\YandaExeMutex`. Nếu Mutex này đã tồn tại, nghĩa là một bản sao khác của mã độc đã đang chạy trên máy rồi nhằm mục đích thực hiện một kỹ thuật rất phổ biến trong mã độc gọi là `Single Instance Enforcement` (Đảm bảo chỉ có một bản sao chạy) để tránh xung đột.

Đáp án: `Global\\YandaExeMutex`

### Task 13: What is the full path of the Command and Control (C2) Binary?

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/HJeeSrthZx.png)

đoạn pseudocode của hàm `sub_1800748E0()`:
```
__int64 sub_1800748E0()
{
  char *v0; // rdi
  __int64 i; // rcx
  HWND WindowW; // rax
  HANDLE CurrentProcess; // rax
  char v5[32]; // [rsp+0h] [rbp-50h] BYREF
  char v6; // [rsp+50h] [rbp+0h] BYREF
  HANDLE hObject; // [rsp+58h] [rbp+8h]
  struct _STARTUPINFOW StartupInfo; // [rsp+80h] [rbp+30h] BYREF
  struct _PROCESS_INFORMATION ProcessInformation; // [rsp+108h] [rbp+B8h] BYREF
  struct _STARTUPINFOW lpStartupInfo; // [rsp+140h] [rbp+F0h] BYREF
  struct _PROCESS_INFORMATION lpProcessInformation; // [rsp+1C8h] [rbp+178h] BYREF
  HWND v12; // [rsp+1F8h] [rbp+1A8h]
  char v13; // [rsp+2D4h] [rbp+284h]

  v0 = &v6;
  for ( i = 130i64; i; --i )
  {
    *(_DWORD *)v0 = -858993460;
    v0 += 4;
  }
  v13 = 0;
  sub_180070FA3(&unk_18019909F);
  hObject = CreateMutexW(0i64, 1, L"Global\\YandaExeMutex");
  if ( !hObject
    || GetLastError() == 183
    || (StartupInfo.cb = 104,
        memset(&StartupInfo.lpReserved, 0, 0x60ui64),
        lpStartupInfo.cb = 104,
        memset(&lpStartupInfo.lpReserved, 0, 0x60ui64),
        (v12 = FindWindowW(0i64, L"Yandex Browser")) != 0i64) )
  {
    CloseHandle(hObject);
  }
  else
  {
    CreateProcessW(
      L"C:\\Users\\Administrator\\AppData\\Local\\Yandex\\YandexBrowser\\Application\\browser.exe",
      0i64,
      0i64,
      0i64,
      1,
      0,
      0i64,
      0i64,
      &StartupInfo,
      &ProcessInformation);
    Sleep(0x2710u);
    WindowW = FindWindowW(0i64, L"yanda.tmp");
    v12 = WindowW;
    if ( !WindowW )
    {
      v13 = 1;
      CreateProcessW(
        L"C:\\Users\\Administrator\\AppData\\Local\\Temp\\yanda.tmp",
        0i64,
        0i64,
        0i64,
        1,
        0,
        0i64,
        0i64,
        &lpStartupInfo,
        &lpProcessInformation);
      Sleep(0x3E8u);
    }
    CloseHandle(ProcessInformation.hProcess);
    CloseHandle(ProcessInformation.hThread);
    if ( !v13 )
      sub_18006E7BC("proc_info2");
    CloseHandle(lpProcessInformation.hProcess);
    CloseHandle(lpProcessInformation.hThread);
    CloseHandle(hObject);
    CurrentProcess = GetCurrentProcess();
    TerminateProcess(CurrentProcess, 0);
  }
  return sub_180070742(v5, &unk_180155D10);
}
```

1. Đầu tiên, nó khởi chạy trình duyệt Yandex hợp lệ: `...\browser.exe`. Đây là hành vi tạo `Decoy` (vỏ bọc).

2. Sau khi sleep 10 giây thì nó sử dụng `FindWindowW(0i64, L"yanda.tmp")` để xem payload này đã chạy chưa.

3. Nếu chưa thấy cửa sổ của nó, mã độc gọi hàm `CreateProcessW` với đường dẫn cụ thể tại `C:\\Users\\Administrator\\AppData\\Local\\Temp\\yanda.tmp`

Đáp án: `C:\\Users\\Administrator\\AppData\\Local\\Temp\\yanda.tmp`

### Task 14: What is the name of the C2 framework used by the attacker?

Quay lại với `Prefetch` thì chúng ta sẽ thấy `Certutil` được gọi đến 2 lần (`16:36:51` và `16:36:11`) 

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/Hk-36m5hZg.png)

Tương ứng với các mốc thời gian thực thi này,artifact `$J` sẽ cho chúng ta thấy 2 file khác nhau
1. File `cert`
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/BkNwJE5n-e.png)
Chính là file mà chúng ta đã reverse ở trên.
2. File `tmp`
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/HJh4x493bl.png)
Chính là file được gọi đến khi `file cert` được thực thi.
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/BkoYe4qhbl.png)
Nhưng vấn đề là author không cung cấp cho chúng ta thư mục `Temp` (aizzzz shiba), vậy thì lấy thông tin của C2 bằng cách nào?
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/SJv-GNch-l.png)
Sau một lúc bị stuck ở đây, nhưng chỉbằng một câu search rất đơn giản thì mình thấy được report sau trên `Any.run`
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/Syw_bN5hbl.png)

https://any.run/report/a64be5730df8ea564739b297be23fa5a27abf2b3f5616dc4d8603b32801a7c5b/9f2e4c1e-cbbe-4f22-90b6-ac29e00d11df 
:)))) lmao, nó có đầy đủ các thông tin mà chúng ta cần.

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/HJayEIFnbe.png)
nó ghi rõ thông tin về C2 framework là `Sliver` luôn.
Đáp án: `Sliver`

### Task 15: What is the IP address and port number of the malicious C2 server used by the attacker?

Cũng dựa vào report Any.run ở trên, chúng ta cũng trả lời được cho câu hỏi này
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/Sherlocks-EasyMoney/ryB6E8KhWx.png)

Đáp án: `18.192.12.126:8888`

Cảm ơn các bạn đã đọc đến đây, chúc một ngày tốt lành

(\\_/)   
(•.•)   
(>☕    
    
SawG, a.k.a EagleBoiz
