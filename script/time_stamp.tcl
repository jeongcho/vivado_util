
set date_str [clock format [clock seconds] -format "%y%m%d%H%M"]
set new_value [format {x"%s"} $date_str]
puts "Generated version string: $new_value"

# Top module 이름 가져오기
set top_name [get_property top [current_fileset]]

# 파일 탐색
foreach f [get_files -of_objects [current_fileset]] {
    set file_path [file normalize $f]
    if {[file exists $file_path]} {
        set fp [open $file_path r]
        set content [read $fp]
        close $fp

        # VHDL Top module인지 확인
        set pattern [format {entity\s+%s\s+is} $top_name]
        if {[regexp $pattern $content]} {
            puts "Top module found in: $file_path"

            # 버전 정보 수정 (백업 만들기)
            set backup_path "$file_path.bak"
            file copy -force $file_path $backup_path
            puts "Backup created at: $backup_path"

            # 줄 단위로 파일 처리
            set modified_lines {}
            set lines [split $content "\n"]
            foreach line $lines {
                if {[regexp {s_version\s*<=\s*x\"[0-9A-Fa-f]+\"} $line]} {
                    set newline "  s_version <= $new_value;"
                    puts "Modified line: $line -> $newline"
                    lappend modified_lines $newline
                } else {
                    lappend modified_lines $line
                }
            }

            # 수정된 내용 저장
            set fp_out [open $file_path w]
            puts $fp_out [join $modified_lines "\n"]
            close $fp_out
            puts "File updated: $file_path"
        }
    }
}

reset_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 16

