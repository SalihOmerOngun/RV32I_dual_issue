Dual issue RISC-V core. Sırasıyla 
FETCH -> ISSUE -> (A) DECODE -> EXECUTE -> SPACE  ->  WRITE BACK
                -> (B) DECODE -> EXECUTE -> MEMORY ->
A datapath'inde Branch ve Integer operasyonlar, B datapth'inde Memory ve Integer işlemleri oluyor.
stall_issue sinyali, paralel olarak iki branch(ya da jump) ya da paralel olarak iki memory işlemi geldiğinde aktif oluyor.
stall_issue_handle sinyali, paralel olarak gelen iki komut arasında RAW, WAW hazard olursa aktif oluyor.
stall sinyali, load komutu ile diğer komutlar arasında RAW hazard olursa aktif oluyor.