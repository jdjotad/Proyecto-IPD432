`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.10.2018 23:02:58
// Design Name: 
// Module Name: Memory_handler
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Memory_handler#(
    parameter MAX_ADDRESS = 39322, //numero de pixeles dividido 5 (ejemplo con 39322 quiere decir una definicion de 512x384) por frame
    parameter NUMBER_OF_PIXELS = 196608, //numero de pixe�es 512*384 en este caso     EN CADA FRAME
    parameter PIXEL_WIDTH = 20, //log2(NUMBER_OF_PIXELS)
    parameter NUMBER_OF_FRAMES = 226 //numero de frames
)(
        input   logic           rst,
        input   logic           rx_ready,// bit que avisa si es que se quiere escribir
        input   logic   [23:0]  uart_rgb_information,  //pixeles acumulados
        output  logic           end_of_write, // se enciende cuando se 'termina' de escribir en la memoria
        //DDR controller ports
        input   logic           clk, //reloj general
        input   logic           clk_ref, //reloj referencia
        input   logic           cpu_resetn,
        output  logic           fifo_read_en,
        output  logic           busy_read,
        output  logic           ui_clk,
        //senales que sirven para la lectura y escritura de la ddr 
        input   logic           fifo_empty,
        input   logic           valid_fifo,
        input   logic           rd_en_in, //gatilla la lectura desde afuera
        input   logic   [23:0]  rd_addr_vga, //direccion de lectura de entrada
        output  logic   [127:0] rd_data_ordered, //salida de la lectura DDR
        output  logic           rd_data_valid, //lectura buena y terminada
        output  logic           ddr_read_ready, // se gatilla luego de haber reordenado los datos que se leen de la ddr 1 ciclo despues de rd_data_valid
        output  logic           full_read_ready,// se gatilla cuando se terminan de leer todos los datos de memoria 
        //memmory signals
        output  logic   [12:0]  ddr2_addr,
        output  logic   [2:0]   ddr2_ba,
        output  logic           ddr2_cas_n,
        output  logic           ddr2_ck_n,
        output  logic           ddr2_ck_p,
        output  logic           ddr2_cke,
        output  logic           ddr2_ras_n, 
        output  logic           ddr2_we_n,
        inout   logic           [15:0] ddr2_dq,
        inout   logic           [1:0] ddr2_dqs_n,
        inout   logic           [1:0] ddr2_dqs_p,
        output  logic           ddr2_cs_n,
        output  logic           [1:0] ddr2_dm,
        output  logic           ddr2_odt
    );
    logic           ui_clk_sync_rst;
    logic   [11:0]  pixel_to_store;
    logic           enable_write;
    
    logic   [127:0] rd_data, rd_data_ordered_next;
    logic   [127:0] wr_data, wr_data_next;
    logic           rd_busy;
    logic           wr_busy;
    logic   [23:0]  wr_addr, wr_addr_next;
    logic           rd_en;
    logic           wr_en;
    
    logic   [25:0]  rd_count_valid, rd_count_valid_next;
    
    logic                       end_of_write_next = 1'b0; 
    logic   [127:0]             rd_data_out_next; 
    logic   [2:0]               pixel_in_line,pixel_in_line_next; //NUMERO DE PIXELES QUE SE HAN GUARDADO EN UNA PALABRA
    logic   [PIXEL_WIDTH-1:0]   pixel_number,pixel_number_next; //numbero de pixeles QUE SE HAN GUARDADO
    logic   [23:0]              write_address_number,write_address_number_next;
    logic   [8:0]               frame_number,frame_number_next;  
    logic                       FINISH_SAVE;//PULSO DE 1 CICLO QUE AVISA TERMINO DE LA ESCRITURA
    
    //------------LOGICA PARA ESCRIBIR EN MEMORIA------------------------------------------------------------------
    enum logic [4:0] {IDLE_WRITE,READ_FIFO, WRITE,WAIT_BUSY,NEXT_MEMORY_ADDRESS} state = IDLE_WRITE, state_next;
    
    
    always_ff@(posedge ui_clk) begin
        if(ui_clk_sync_rst)begin
            end_of_write <='d0;
            wr_addr <= 'd0;
            pixel_in_line <= 'd0;
            pixel_number <= 'd0;
            frame_number<='d0;
            write_address_number<='d0;
            state <= IDLE_WRITE;
        end
        else begin
            write_address_number<=write_address_number_next;
            wr_addr <= wr_addr_next;
            pixel_in_line <=pixel_in_line_next;
            pixel_number<= pixel_number_next;
            wr_data <= wr_data_next;
            state <= state_next;
            end_of_write<=end_of_write_next;
            frame_number<=frame_number_next;
        end
    end
    always_comb begin
        wr_en = 1'b0;
        fifo_read_en = 1'b0;
        FINISH_SAVE = 1'b0;
        end_of_write_next = end_of_write;
        wr_addr_next = wr_addr;
        write_address_number_next = write_address_number;
        pixel_in_line_next = pixel_in_line;
        pixel_number_next = pixel_number;
        frame_number_next = frame_number;
        wr_data_next = wr_data;
        state_next = state;
        case(state)
            IDLE_WRITE: 
                begin
                    if(!fifo_empty) begin //APENAS SE BAJE LA SE�AL DE QUE LA FIFO ESTA VACIA SE COIENZA LA LECTURA DE LA MISMA
                        state_next = READ_FIFO;
                        fifo_read_en = 1'b1;
                    end
                end      
            READ_FIFO://SE ASIGNA EL VALOR LEIDO EN LA FIFO AL REGISTRO DE PIXEL CORRESPONDIENTE SEGUN EL PIXEL_IN_LINE
                begin
                    if(valid_fifo)begin
                        case(pixel_in_line)
                        3'd0:wr_data_next[23:0] = uart_rgb_information;
                        3'd1:wr_data_next[47:24] = uart_rgb_information;
                        3'd2:wr_data_next[71:48] = uart_rgb_information;
                        3'd3:wr_data_next[95:72] = uart_rgb_information;
                        3'd4:wr_data_next[127:96] = {8'd0,uart_rgb_information};    
                        endcase
                        
                        pixel_number_next = pixel_number +'d1;
                        pixel_in_line_next = pixel_in_line +'d1;
                        state_next = IDLE_WRITE;
                        if(pixel_in_line == 3'd4||pixel_number==NUMBER_OF_PIXELS-1)begin 
                            state_next = WRITE;
                        end    
                    end
                
                end
            
            WRITE: //SE GUARDA EN MEMORIA
                begin
                    if(!wr_busy)begin                
                        wr_en = 1'b1;
                        state_next = WAIT_BUSY;
                    end
                end
            WAIT_BUSY:
                begin
                    if(!wr_busy)state_next = NEXT_MEMORY_ADDRESS;
                end
            
            NEXT_MEMORY_ADDRESS: //SIGUIENTE DIRECCION DE MEMORIA
                begin
                    pixel_in_line_next = 'd0; 
                    wr_data_next = 128'd0;
                    state_next = IDLE_WRITE;
                    wr_addr_next = wr_addr + 24'd1;
                    write_address_number_next = write_address_number +'d1;
                    if(write_address_number == MAX_ADDRESS-1)begin
                        frame_number_next = frame_number + 'd1;
                        write_address_number_next = 'd0;
                        pixel_number_next = 'd0;
                        if(frame_number == NUMBER_OF_FRAMES-1)begin
                            FINISH_SAVE = 1'b1;
                            end_of_write_next = 1'b1;
                            pixel_number_next = 'd0;
                            frame_number_next = 'd0;
                        end
                    end
                end

        endcase
            
    end
    
    
    
 //-----LOGICA PARA LECTURA DE LA MEMORIA DDR     
    enum logic[1:0]{IDLE_READ,READ_FINISH} state_act, next_state;
    
    logic                   ddr_read_ready_next;
    logic [8:0]             rd_number_frames,rd_number_frames_next;
    logic [PIXEL_WIDTH-1:0] rd_address_number,rd_address_number_next; //cuenta la cantidad de direcciones leidas
    logic                   full_read_ready_next;    
    always_ff@(posedge ui_clk)begin
        if(ui_clk_sync_rst)begin
            state_act <=IDLE_READ;
            rd_address_number<='d0;
        end
        else begin
            rd_data_ordered<=rd_data_ordered_next;
            state_act <= next_state;
            ddr_read_ready<=ddr_read_ready_next;
            rd_address_number<=rd_address_number_next;
            rd_number_frames <= rd_number_frames_next;
            full_read_ready<=full_read_ready_next;
        end
    end

    
    
  
    always_comb begin
        next_state = state_act;
        ddr_read_ready_next = ddr_read_ready;
        rd_data_ordered_next = rd_data_ordered;
        rd_address_number_next = rd_address_number;
        rd_number_frames_next = rd_number_frames;
        full_read_ready_next = full_read_ready;
        rd_en = 1'b0;
        case(state_act)
            IDLE_READ: 
                begin
                    ddr_read_ready_next = 1'b0;
                    full_read_ready_next = 1'b0;
                    if(!wr_busy&&end_of_write_next&&rd_en_in)begin
                        rd_en = 1'b1;
                        next_state = READ_FINISH;
                    end
                end      
            READ_FINISH: 
                begin
                    if(rd_data_valid) begin
                        rd_data_ordered_next = rd_data;
                        ddr_read_ready_next = 1'b1;
                        next_state = IDLE_READ;
                     
                        if(rd_address_number==MAX_ADDRESS-1)begin
                            if(rd_number_frames ==NUMBER_OF_FRAMES-1)begin
                                rd_number_frames_next = 'd0;
                                full_read_ready_next = 1'b1;                   
                            end
                            else  rd_number_frames_next = rd_number_frames +'d1;       
                            rd_address_number_next = 'd0;
                        end
                        else rd_address_number_next = rd_address_number +'d1;
                    end
                end
        endcase
    
    end
  //-------------------------------------------------------------------------------------

  
    

 //---------------------------------------------------------------------------------------   
    
    
    
    ddr_ram_controller_mig #(
        .BOARD("NEXYS_DDR")) your_inst_name(
        // user interface signals
        .ui_clk             (ui_clk),
        .ui_clk_sync_rst    (ui_clk_sync_rst),
        .wr_addr            (wr_addr),
        .wr_data            (wr_data),
        .rd_addr            (rd_addr_vga),
        .rd_data            (rd_data),
        .wr_en              (wr_en),
        .rd_en              (rd_en),
        .wr_busy            (wr_busy),
        .rd_busy            (rd_busy),
        .rd_data_valid      (rd_data_valid),
        // phy signals
        .clk_p(),
        .clk_n(),
        
        .clk                (clk),
        .clk_ref            (clk_ref),
        .rst                (cpu_resetn),
        .ddr_addr          (ddr2_addr),
        .ddr_cs_n          (ddr2_cs_n), 
        .ddr_ba            (ddr2_ba),
        
        .ddr_cas_n         (ddr2_cas_n),
        .ddr_ck_n          (ddr2_ck_n), 
        .ddr_ck_p          (ddr2_ck_p), 
        .ddr_cke           (ddr2_cke),  
        .ddr_ras_n         (ddr2_ras_n),
        .ddr_reset_n       (reset),
        .ddr_we_n          (ddr2_we_n), 
        .ddr_dq            (ddr2_dq),
        .ddr_dqs_n         (ddr2_dqs_n),
        .ddr_dqs_p         (ddr2_dqs_p),
        .ddr_dm            (ddr2_dm),
        .ddr_odt           (ddr2_odt)
    );
    assign busy_read = rd_busy;                          

endmodule
