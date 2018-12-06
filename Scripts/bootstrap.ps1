

#copy modules into the host rather than download them from the web, which is proving unreliable

try {
Copy-Item "C:\vagrant_data\Modules\" -destination "C:\Program Files\WindowsPowershell" -force -recurse 
}

catch {
    throw
}