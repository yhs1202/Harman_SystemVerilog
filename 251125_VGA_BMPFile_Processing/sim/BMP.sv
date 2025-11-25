class BMP;
  byte bmpHeader[54];
  byte bmpImgData[640*480*3];

  int fd;  // File descriptor (for file operations)
  string filePath;

  function new(string filePath, string mode);
    this.filePath = filePath;
    open(filePath, mode);
  endfunction

  // file Open
  function int open(string filePath, string mode);
    // Open BMP file
    fd = $fopen(filePath, mode);
    if (!fd) begin
      $display("Error: Unable to open BMP file %s", filePath);
    end else begin
      $display("BMP file %s opened successfully", filePath);
    end
    return fd;
  endfunction

  // Close the file
  function void close();
    $fclose(fd);
    $display("%s file closed", filePath);
  endfunction


  // File Read
  function int read();
    int size = 0;
    // Read BMP header
    size = $fread(bmpHeader, fd);  // 54 bytes
    $display("%s BMP Header read successfully, header size = %0d bytes", filePath, size);

    // Read BMP image data
    size = $fread(bmpImgData, fd);  // 640*480*3 bytes
    $display("%s BMP Image data read successfully, image data size = %0d bytes", filePath, size);
  endfunction

  // File Write
  function write(byte imgData[], int size);
    for (int i = 0; i < size; i++) begin
      $fwrite(fd, "%c", imgData[i]);
    end
  endfunction

  // File Flush
  function void flush();
    $fflush(fd);
  endfunction

endclass : BMP
