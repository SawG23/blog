---
title: AMSI Bypass - Nguyên lý cốt lõi và góc nhìn của BlueTeam
description: "Phân tích cơ chế hoạt động của AMSI,một vài kĩ thuật bypass, và góc nhìn của BlueTeam."
published: 2026-06-23
tags: ["AMSI","Bypass Techniques","AsyncRAT","Sharing"]
category: Sharing
draft: false
---

`Antimalware Scan Interface (AMSI)` là lá chắn đắc lực của Microsoft giúp phát hiện và ngăn chặn fileless malware hay các script độc hại (PowerShell, VBScript) chạy trực tiếp trên bộ nhớ. Tuy nhiên, trong cuộc đua bảo mật, kẻ tấn công luôn tìm cách vượt mặt cơ chế này bằng nhiều kỹ thuật tinh vi, từ làm rối mã (Obfuscation) đến can thiệp trực tiếp vào bộ nhớ (Memory Patching).
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/By2hUm4MMe.png)
Trong blog này, chúng ta sẽ đi sâu vào cơ chế hoạt động của AMSI, khám phá các kỹ thuật bypass phổ biến và phân tích thực tế một số mẫu mã độc áp dụng phương pháp này.

# 1. Antimalware Scan Interface là gì?
theo tài liệu của microsoft
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/rJ7KdQEzMl.png)
Đại khái thì:
> AMSI (Windows Antimalware Scan Interface) là một chuẩn interface trung gian cho phép các ứng dụng tích hợp trực tiếp với bất kỳ phần mềm diệt virus (AV) nào trên hệ thống để tăng cường khả năng bảo vệ.

Các đặc điểm cốt lõi:

* Độc lập (Vendor-agnostic): Tương thích với mọi hãng phần mềm diệt virus.
* Quét đa nền tảng: Hỗ trợ quét tệp tin, bộ nhớ (memory), luồng dữ liệu (stream) và kiểm tra mức độ uy tín của URL/IP.
* Tương quan theo phiên (Session-based): Cho phép phần mềm AV xâu chuỗi và phân tích các mảnh payload rời rạc trong cùng một phiên hoạt động, giúp phát hiện các kỹ thuật lẩn tránh tinh vi một cách chính xác hơn so với việc quét đơn lẻ.

Một số thành phần tích hợp với AMSI là:
* User Account Control, or UAC (elevation of EXE, COM, MSI, or ActiveX installation)
* PowerShell (scripts, interactive use, and dynamic code evaluation)
* Windows Script Host (wscript.exe and cscript.exe)
* JavaScript and VBScript
* Office VBA macros

# 2. AMSI hoạt động như thế nào?
![image](https://learn.microsoft.com/en-us/windows/win32/amsi/images/amsi7archi.jpg)

1. `Tầng Ứng dụng`: Các chương trình như PowerShell hoặc VBScript gửi dữ liệu thô (script chưa mã hóa) xuống hệ thống để yêu cầu kiểm tra.
2. `Win32 API`: Dữ liệu đi vào thư viện AMSI.dll thông qua các hàm như AmsiScanBuffer() hoặc AmsiScanString().
> Đây là điểm yếu thường bị tấn công nhất. Attacker thường dùng Memory Patching can thiệp trực tiếp vào AmsiScanBuffer để ép hàm này trả về kết quả "An toàn" ngay lập tức.
3. `COM & Provider`: AMSI.dll sẽ kiểm tra Registry xem máy tính đang dùng Antivirus nào (Windows Defender hay hãng thứ 3) để chuyển hướng yêu cầu đến đúng provider tương ứng.
4. `RPC`: Dữ liệu được truyền qua kênh RPC (Remote Procedure Call) để đi từ tiến trình của ứng dụng sang tiến trình của phần mềm diệt virus một cách độc lập.
5. `Scan Engine`: Tiến trình diệt virus (ví dụ MsMpEng.exe của Defender) sẽ tiếp nhận dữ liệu, thực hiện quét (signature, heuristic) và trả về "phán quyết" cuối cùng (Sạch hay Độc hại) để ứng dụng quyết định việc thực thi.

# 3. Phân tích amsi.dll với IDA
Để phân tích sâu hơn thì chúng ta dùng ida và load amsi.dll để phân tích
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/B14JbNEGze.png)
amsi.dll có thể dễ dàng tìm thấy ở thư mục `System32`, copy ra thư mục ngoài để phục vụ phân tích.
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/BkBQGNVMfl.png)

## 3.1. AmsiInitialize()
Khi một tiến trình (như powershell.exe) vừa khởi chạy, nó chưa thể quét mã độc ngay. Việc đầu tiên nó làm là gọi hàm `AmsiInitialize` để "đánh thức" AMSI.
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/SkvmAwNGMg.png)
Quá trình này diễn ra qua 3 bước cốt lõi:
### 3.1.1. Cấp phát amsiContext và Magic Header
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/rkPa1OVMMg.png)
* Sau khi xin hệ điều hành một vùng nhớ (CoTaskMemAlloc), AMSI lập tức đóng dấu vào 4 byte đầu tiên với giá trị là `0x49534D41`, tương đương với chuỗi ASCII `"AMSI"`.
* Ở phần `AmsiScanBuffer` tiếp theo, chúng ta sẽ thấy hệ thống kiểm tra lại chính "con dấu" này để đảm bảo dữ liệu không bị giả mạo trước khi cho phép quét.
### 3.1.2. Caller Identification

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/r15ZmOVMfg.png)
* Process gọi phải cung cấp tên định danh thông qua tham số appName (ví dụ: chuỗi "PowerShell"). Chuỗi dữ liệu này được sao chép trực tiếp vào vùng nhớ và liên kết vào thuộc tính thứ hai của cấu trúc Context.
### 3.1.3. Khởi tạo Engine Scan COM
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/Hyg_IdNffg.png)

* AMSI sử dụng định danh `CLSID_Antimalware` để truy vấn Windows Registry, qua đó xác định module Antivirus Provider nào đang được ủy quyền trên hệ thống (Windows Defender, CrowdStrike, Kaspersky...). API DllGetClassObject sẽ trả về một đối tượng COM Factory (ppv).

Ngay sau đó, quá trình VTable Dispatching được thực thi:
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/HkIfvdEfMg.png)
* Bằng cách gọi phương thức tại offset +24 (tương ứng với hàm `CreateInstance` trong cấu trúc COM), AMSI yêu cầu Provider khởi tạo một object `IAntimalware`. Object này đại diện cho engine phân tích lõi của AV — sau đó được ánh xạ vào vị trí thứ ba (v9 + 4) trong cấu trúc Context.

Với `AMSICONTEXT` đã được cấp phát và liên kết thành công với Antivirus Provider. Ở giai đoạn tiếp theo, cấu trúc dữ liệu này sẽ được truyền vào hàm `AmsiScanBuffer()`


## 3.2. AmsiScanBuffer()

Sau khi `AmsiInitialize` thiết lập xong kênh liên lạc và tạo ra một `amsiContext` hoàn chỉnh, hệ thống đã sẵn sàng. Khi một process cố gắng thực thi mã (script, macro), dữ liệu thô sẽ được đẩy vào `AmsiScanBuffer()`
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/HJbrmV4zze.png)


### 3.2.1. `Validate đầu vào` — cũng là điểm yếu của `amsi.dll`

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/B1qQBHVzMx.png)

Hàm kiểm tra tuần tự `buffer`, `length`, `result`, `amsiContext`, `magic signature`, `provider pointer`. Tất cả nhánh fail đều trả về cùng một mã `E_INVALIDARG` (0x80070057).
→ Đây chính là cơ sở của kỹ thuật "`AMSI patch bypass`": chỉ cần ép hàm nhảy thẳng vào nhánh return sớm này (patch vài byte đầu function), nội dung sẽ không bao giờ đến AV engine mà vẫn trả mã lỗi như đang hoạt động bình thường — rất khó phát hiện bằng cách kiểm tra return code đơn thuần.

### 3.2.2. `CAmsiBufferStream`

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/SynbdSNMzx.png)
AMSI không truyền buffer thô cho AV. Nó dựng một object ngay trên stack (gán thủ công con trỏ vtable), bọc (buffer, length) thành dạng stream chuẩn — giống cách `COM IStream` hoạt động. Đây là `Abstract Class` giúp mọi AV vendor xử lý dữ liệu theo cùng một `interface`, bất kể nguồn gốc (script, macro, JS...).

### 3.2.3. `Dispatch qua vtable`

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/ryGptrVzfx.png)
Offset `+24` (slot thứ 4, sau QueryInterface/AddRef/Release) chính là phương thức `Scan()` của interface `IAntimalwareProvider`.
Tóm lại toàn bộ đoạn code này tương đương:
`return v10->Scan(&streamObject, result, 0);`

> AMSI thực chất chỉ là một lớp trung gian (broker), nó hoàn toàn không phải là một engine quét mã độc. Nhìn vào mã Assembly, ta thấy nó chỉ làm đúng 3 việc: Xác thực context (Magic Header) → Đóng gói dữ liệu (CAmsiBufferStream) → Gọi VTable của AV Provider (hàm Scan).
> 
> Vì vậy, mọi kỹ thuật bypass AMSI đều tập trung vào việc "bịt mắt" hoặc "cắt đứt" luồng giao liên này trước khi dữ liệu kịp chạm đến engine quét thực sự (như Windows Defender).

# 4. AMSI kết hợp cùng ETW

Một trong những vấn đề đau đầu nhất của phân tích mã độc là xử lý các đoạn script bị làm rối (Obfuscated). Kẻ tấn công liên tục đổi mới phương thức mã hóa nhằm qua mặt signature của Antivirus. Tuy nhiên, chúng vướng phải một điểm nghẽn chí mạng ở kiến trúc hệ điều hành: CPU không thể chạy các đoạn mã Base64 hay bất kì phương thức obfuscate nào. Script bắt buộc phải được giải mã để chạy bình thường.

Chính tại khoảnh khắc payload hiện nguyên hình trên RAM, AMSI sẽ can thiệp. Thay vì mòn mỏi ngồi dịch ngược các hàm giải mã tĩnh, chúng ta có thể "ngồi ôm cây đợi thỏ" nhờ vào sức mạnh của ETW (Event Tracing for Windows).

ETW là một cơ sở hạ tầng thu thập nhật ký (telemetry) tốc độ cao nằm sâu trong Kernel của Windows. Do AMSI được tích hợp sẵn như một ETW Provider, chúng ta có thể sử dụng công cụ dòng lệnh logman để ghi lại mọi động thái của nó:


`logman start AMSITrace -p "Microsoft-Antimalware-Scan-Interface" -o AMSITrace.etl -ets`

Khi quá trình kích hoạt mã độc kết thúc, chúng ta chỉ cần dừng phiên theo dõi:

`logman stop AMSITrace -ets`

File `.etl` thu được là một trong những artifact quan trọng khi phân tích các loại malware có sử dụng kĩ thuật `bypass AMSI` này. Nó cho chúng ta biết chính xác AMSI được gọi khi nào, engine nào đã kích hoạt nó, và quan trọng nhất: toàn bộ nội dung script nguyên bản trước khi thực thi.

Vì sample mã độc toi chọn nó bypass luôn ETW và vì khá lười để tìm sample khác, nên đây là blog trong các bạn muốn tìm hiểu thêm [Accelerating Malicious Script Analysis with AMSI](https://theshadowslights.com/posts/malware-analysis/02/#your-obfuscation-means-nothing)

# 5. Case study về kĩ thuật AMSI Bypass
## 5.1 Overview
Để hiểu rõ hơn về cách mà attacker vượt mặt AMSI, chúng ta sẽ phân tích sample mã độc `AsyncRAT` có sử dụng kỹ thuật Memory Patching, kết hợp vô hiệu hóa cả AMSI và ETW logging để tạo chuỗi bypass khá tinh vi và tiên tiến.

![image](https://img.helpnetsecurity.com/wp-content/uploads/2025/07/14205950/asyncrat-1500.webp)

Theo [cyble.com](https://cyble.com/blog/null-amsi-evading-security-to-deploy-asyncrat/): Cyble Research and Intelligence Labs (CRIL) đã phát hiện một chiến dịch tấn công sử dụng các file LNK độc hại được ngụy trang thành wallpaper nhằm lừa người dùng thực thi chúng. Chiến dịch này được đặt tên "Ghost in the Shell" — một cái tên không phải ngẫu nhiên khi toàn bộ payload được thực thi hoàn toàn trong memory, không để lại dấu vết trên disk.

Cụ thể, các file LNK được thể hiện dưới dạng wallpaper anime với các nhân vật nổi tiếng như Sasuke và Itachi Uchiha từ Naruto — khai thác tâm lý và sở thích của người dùng để tăng xác suất bị lừa click. 

## 5.2 Infection chain
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/Bk-f1RwzMx.png)
*Nguồn ảnh: [Cyble - NULL AMSI: Evading Security to Deploy AsyncRAT](https://cyble.com/blog/null-amsi-evading-security-to-deploy-asyncrat/)*
## 5.3 AMSI, ETW Bypass
Từ phân tích ở trên,ta biết được AmsiScanBuffer() có cấu trúc:
* Validate đầu vào (magic signature, pointer checks)
* Đóng gói dữ liệu thành `CAmsiBufferStream`
* Dispatch qua `vtable` đến `AV provider`

Kỹ thuật bypass này tận dụng điểm yếu chính mà chúng ta đã xác định: nhánh return sớm trong validation.Nhưng thay vì chỉ patch `AmsiScanBuffer`, sample này đi sâu hơn — nó vô hiệu hóa `AmsiInitialize`, hàm khởi tạo context của AMSI mà chúng ta đã nói ở trên:
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/rkOpDTPfMx.png)

* Nó đang sử dụng kĩ thuật `Hex Byte Array Encoding` nhằm vượt qua các cơ chế kiểm tra tĩnh và lấy địa chỉ `AmsiInitialize` thông qua reflection
* Ngoài ra các chuỗi khác cũng dùng kĩ thuật Encoding tương tự
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/SkKlrBSGzx.png)

> Tại sao chọn `AmsiInitialize` thay vì `AmsiScanBuffer`?
* `AmsiInitialize` là pinch point duy nhất: Mỗi khi PowerShell khởi động, nó bắt buộc phải gọi AmsiInitialize để tạo context handle (systemContext) — đây là cơ sở của toàn bộ luồng quét sau này.
* Vô hiệu hóa từ gốc: Bằng cách patch `AmsiInitialize` trả về `S_OK (0)` nhưng không thực tế tạo `context` hợp lệ, các hàm quét tiếp theo sẽ phải xử lý một `context "rỗng"` — và hầu hết code AV không prepare cho scenario này.

### 5.3.1. AMSI - Opcode Patching
* Opcode cần patch: "`mov eax, 0; ret`" (6 bytes) 
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/r16-O6vffg.png)
* `Bước 1`: Loại bỏ write protection
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/HysOdTvMzg.png)
    * `VirtualProtect` (`PAGE_EXECUTE_READWRITE`): Gọi API `VirtualProtect()` để thay đổi quyền truy cập của vùng bộ nhớ chứa hàm `AmsiInitialize` từ `RX` (chỉ đọc/thực thi) sang `RWX` (đọc/ghi/thực thi). Điều này là bắt buộc vì Windows kernel mặc định chặn ghi dữ liệu vào code section.
* `Bước 2`: Ghi opcode mới vào bộ nhớ
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/HJC0upDffx.png)
Copy 6 bytes opcode vào vùng nhớ của AmsiInitialize. `Opcode 0xb8 0x00 0x00 0x00 0x00 0xc3` tương ứng với x86 assembly:
    * `0xb8` = MOV EAX
    * `0x00 0x00 0x00 0x00` = value 0 (`HRESULT` thành công)
    * `0xc3` = RET 
Kết quả: hàm sẽ luôn trả về `S_OK (0)` mà không thực hiện công việc thực sự — một `"return statement bịp"` về mặt logic.
* `Bước 3`: Verify
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/BJDmKaPzMg.png)
    * Đọc lại từng byte vừa ghi để kiểm tra patch có thành công hay không. Điều này cực kỳ quan trọng vì:
Một số hệ thống có `Data Execution Prevention` (DEP) hoặc đã patch Windows kernel để chặn việc ghi vào code section
    * Nếu verification fail, script thoát ngay thay vì tiếp tục với một patch bị lỗi
* `Bước 4`: Khôi phục write protection
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/Skf_KpPMGx.png)
    * Đổi quyền truy cập ngược lại từ RWX sang RX. Kỹ thuật này là anti-forensic — nó che giấu dấu vết của quá trình patch bằng cách khôi phục lại tình trạng ban đầu của memory page.

### 5.3.2. Vô hiệu hóa ETW Event Logging
Nhưng đó chưa phải hết. Ở phần trên chúng ta đã thảo luận rằng ETW là deep kernel infrastructure — nó ghi lại hầu như mọi thứ, bao gồm cả nội dung script được AMSI scan. Để tránh để lại dấu vết hoàn toàn, script tiếp tục:
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/ByKIcaPffl.png)

* `EtwEventWrite` (ntdll.dll) là hàm kernel-mode gateway — mọi ETW event từ user-mode đều phải đi qua đây.
* Patch nó để `return ngay lập tức` = mọi ETW event sẽ bị "quất:))" trước khi kịp ghi vào kernel log.
* Sau stage này, ngay cả logman cũng sẽ không thấy bất kỳ artifact nào.


### 5.3.3 một số kĩ thuật khác
#### Accessing Undocumented APIs
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/H1j0-rrzze.png)
#### Indirect API Call
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/BkAy7HSffl.png)
#### ARCHITECTURE-AWARE
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/HkjCHrrMze.png)

vì các kĩ thuật trên không nằm trong topic của blog, nên toi sẽ không đi sâu vào nó, các bạn có thể tải sample và tự nghiên cứu thêm.

### 5.4. Kraken - Sherlock HackTheBox
Trong lúc research về kĩ thuật này, toi vô tình nhận ra, sample mà author dùng trong challenge rất tương đồng với `AsyncRAT` (chỉ khác về tên biến, một vài syntax). Có vẻ author đã lấy ý tưởng về chiến dịch lần này của asyncRAT. Challenge này toi có đã có làm một writeup về nó, các bạn có thể tham khảo.
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/Byclx4HGfl.png)

# 6. Góc nhìn của Blue Team
Sau khi đi qua toàn bộ cơ chế hoạt động của AMSI và các kỹ thuật attacker dùng để vô hiệu hóa nó, câu hỏi cần đặt ra là: nếu AMSI đã bị blind, chúng ta còn có thể detect từ đâu?Câu trả lời nằm ở một nguyên tắc cốt lõi: dù attacker có bypass được AMSI hay ETW, hành vi thao túng bộ nhớ vẫn để lại dấu vết ở tầng thấp hơn — nơi mà các kỹ thuật evasion thông thường không với tới được. Ngoài ra trước khi bypass thành công, thì với những hành vi thao tác bộ nhớ, chúng đã để lại các artifact rất rõ ràng trên hệ thống.

## 6.1. Sysmon Event ID 10
Mọi kỹ thuật AMSI bypass theo hướng memory patching — dù là patch `AmsiScanBuffer`, `AmsiInitialize`, hay `AmsiOpenSession` — đều phải trải qua một bước không thể bỏ qua: truy cập vào vùng nhớ của `amsi.dll` đang được load trong process đích để ghi đè opcode.
Sysmon ghi lại hành vi này qua **EID 10 — ProcessAccess**, hoạt động qua kernel driver riêng (**SysmonDrv**), hoàn toàn độc lập với `ETW pipeline` của `AMSI`. Đây là lý do EID 10 trở thành nguồn artifact đáng tin cậy nhất: dù `EtwEventWrite` trong `ntdll.dll` bị patch, Sysmon vẫn ghi log bình thường vì nó không đi qua con đường đó.
Điểm cần chú ý trong `CallTrace`: khi patch xảy ra từ unbacked memory — tức là vùng nhớ không được map với bất kỳ module nào trên disk — đây là dấu hiệu mạnh của shellcode hoặc reflective loading. Kết hợp với TargetImage trỏ vào các script host như `powershell.exe`, `wscript.exe`, `cscript.exe`, pattern này gần như chắc chắn là malicious.
> Dù mạnh mẽ, sysmon ID 10 tồn tại một nhược điểm lớn: Chỉ nhạy với Cross-Process và **hoàn toàn bất lực trước kỹ thuật Self-Patching**. Khi một biến thể mã độc tự can thiệp vào bộ nhớ của chính nó (Intra-process) bằng cách gọi trực tiếp các API thông qua pseudo-handle, luồng thực thi hoàn toàn bypass qua cơ chế ObRegisterCallbacks của Sysmon driver ở tầng Kernel. Trong kịch bản này, ID 10 sẽ trả về con số 0 tròn trĩnh, buộc chúng ta phải chuyển hướng sang phối hợp với các lớp phòng thủ khác như `PowerShell EID 4104`.

## 6.2. PowerShell Script Block Logging — Event ID 4104

Để hiểu tại sao EID 4104 quan trọng, cần hiểu trước một constraint mà **attacker không thể tránh khỏi**.
Các script host như VBScript (**wscript.exe**, **cscript.exe**) hay **mshta.exe** bị giới hạn nghiêm ngặt về khả năng tương tác với bộ nhớ hệ thống. Chúng không có native access đến các API như **VirtualProtect**, **Marshal.Copy**, hay reflection để truy cập internal field của .NET runtime. Muốn thao túng sâu vào bộ nhớ — tức là muốn thực hiện memory patching lên `amsi.dll` — **attacker bắt buộc phải leo lên PowerShell**.

PowerShell chạy trên .NET runtime, có đầy đủ quyền truy cập vào `System.Runtime.InteropServices`, `System.Reflection`, P/Invoke, và toàn bộ Win32 API surface. Đây là môi trường duy nhất trong Windows scripting stack cho phép attacker làm những việc như:
```
# Truy cập internal field của .NET runtime qua reflection
$a = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
$b = $a.GetField('amsiInitFailed','NonPublic,Static')

# Gọi Win32 API trực tiếp qua P/Invoke
$vp = [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(...)
VirtualProtect($addr, 6, 0x40, [ref]$old)
```
EID 4104 ghi lại payload tại thời điểm PowerShell engine đã làm hết phần decode thay cho chúng ta, và nó xuất hiện trước khi attacker kịp làm bất cứ điều gì để xóa dấu vết.

Nhìn vào hai mẫu log thu thập được từ quá trình thực thi `AsyncRAT`, chúng ta có thể thấy rõ chiến thuật phân lớp của kẻ tấn công:
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/rkzr30DGfl.png)
* Khối mã nguồn sau khi giải mã (lưu trữ trong biến `$injectionCode`) chứa đựng toàn bộ logic P/Invoke và Reflection nhằm vô hiệu hóa AMSI và ETW (chi tiết tại Ảnh 2). Tại đây, Event ID 4104 thể hiện rõ vai trò trọng yếu: Ghi nhận chính xác khoảnh khắc Loader thực thi quá trình de-obfuscation Base64, bóc được payload lõi ngay trước khi mã độc kịp vô hiệu hóa các lá chắn phòng thủ của hệ thống.

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/AMSI/BkDFXXdMfe.png)
* Bức ảnh thứ hai chính là nội dung của $injectionCode đã được giải mã, đây là toàn bộ logic cốt lõi để bypass AMSI/ETW mà chúng ta đã phân tích ở phần 5.3.

Để khám phá thêm sự đa dạng của các attack surface, các bạn có thể tham khảo thêm repository [Amsi-Bypass-Powershell](https://github.com/S3cur3Th1sSh1t/Amsi-Bypass-Powershell) . Đây là một dự án tổng hợp hệ thống các kỹ thuật bypass AMSI tiên tiến dành riêng cho mục đích nghiên cứu.

Tóm lại, với những chia sẻ trên thì toi cũng coi như có cái note để đọc lại khi quên và cũng mong là nó giúp ích gì đó cho các bạn. Đến đây thì blog cũng đã dài. Cảm ơn các bạn đã dành thời gian để đọc đến đây. Chúc một ngày tốt lành

(\\_/)

(•.•)

(>☕    
    
SawG, a.k.a EagleBoiz

# 🔍 Indicators of Compromise (IOCs)
| Type | Indicator / Value 
| :--- | :--- | 
| **SHA256** | `04fc833b59af93308029d3e87c85e327a1e480508bc78b6a4e46c0cbd65ea8dc`|
| **File Name** | `8KuV.ps1` |


# 📚 Tài liệu tham khảo

1. https://learn.microsoft.com/en-us/windows/win32/amsi/antimalware-scan-interface-portal
2. https://learn.microsoft.com/en-us/windows/win32/api/amsi/nn-amsi-iantimalwareprovider
3. https://porotnikov.com/post/windows/2023-09-05-understanding-amsi-the-antimalware-scan-interface-in-windows-systems/
4. https://theshadowslights.com/posts/malware-analysis/02/
5. https://cyble.com/blog/null-amsi-evading-security-to-deploy-asyncrat/