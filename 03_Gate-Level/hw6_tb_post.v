`timescale 1ns / 1ns
`define period          10
`define img_max_size    224*224*3+54
`define cat56_size    	56*56
//---------------------------------------------------------------
//You need specify the path of image in/out
//---------------------------------------------------------------
`define path_img_in     "../00_Source/cat224.bmp"
`define path_img_out    "../00_Source/cat56.bmp"
`define path_res_img    "./01_Image/"
`define path_bias       "../00_Source/conv1_bias_hex.txt"
`define path_kernel     "../00_Source/conv1_kernel_hex.txt"
`define path_sdf        "../02_Synthesis/dc_out_file/HDL_HW6_syn.sdf"

module HDL_HW6_TB;
    integer img_in,bias_in;
    integer img_out;
    integer offset;
    integer img_h;
    integer img_w;
    integer img_ch;
    integer idx;
	integer jdx;
	integer kdx;
    integer header;
	integer i,j;
    reg         clk,reset;
    reg  [7:0]  img_data [0:`img_max_size-1];
    reg  [7:0]  img_data_56 [0:55][0:55][2:0];
    reg  [7:0]  img_data_56_padding [0:57][0:57][2:0];
    reg  [7:0]  R;
    reg  [7:0]  G;
    reg  [7:0]  B;

    reg  [11:0]  R_resize;
    reg  [11:0]  G_resize;
    reg  [11:0]  B_resize;	
    reg  [7:0]  R_56x56;
    reg  [7:0]  G_56x56;
    reg  [7:0]  B_56x56;

    reg [15:0]bias_data[0:63];

    reg input_sram_en,input_sram_wr_en;
    reg [13:0]input_sram_wr_addr,input_sram_rd_addr;
    reg [7:0]input_sram_data;
    wire[7:0]input_sram_out_data;

    integer rf_i;
    reg bias_rf_en,bias_rf_wr_en;
    reg [3:0]bias_rf_rd_addr,bias_rf_wr_addr;
    reg [15:0]bias_rf1_wr_data,bias_rf2_wr_data,bias_rf3_wr_data,bias_rf4_wr_data;
    wire [15:0]bias_rf1_rd_data,bias_rf2_rd_data,bias_rf3_rd_data,bias_rf4_rd_data;

    integer kernel_i,kernel_j,kernel_k,test;
    reg [15:0]kernel_data[0:1728];
    reg kernel_rf_en,kernel_rf_wr_en;
    reg [8:0]kernel_rf_wr_addr;
    reg [8:0]kernel1_rf_rd_addr,kernel2_rf_rd_addr,kernel3_rf_rd_addr,kernel4_rf_rd_addr;
    reg [15:0]kernel1_rf_wr_data,kernel2_rf_wr_data,kernel3_rf_wr_data,kernel4_rf_wr_data;
    wire [15:0]kernel1_rf_rd_data,kernel2_rf_rd_data,kernel3_rf_rd_data,kernel4_rf_rd_data;

    reg ps_sram_en;
    reg [11:0]ps_sram_addr;
    reg ps_sram_rst_en;

    wire [35:0]result1,result2,result3,result4;

    wire cal_en,valid;
    
    integer pix_idx,round_counter,bias_counter,kernel_counter,kernel_pix,ps_sram_rst,write_out;

    integer layer1_img_handle[63:0];
    reg [255:0]file_name1;
    reg [7:0] digit1, digit2;
    reg [15:0]counter;
    //---------------------------------------------------------------
    //Insert your  verilog module at here
    //
    TOP U1( .clk(clk),.reset(reset),
            .input_sram_en(input_sram_en),.input_sram_wr_en(input_sram_wr_en),
            .input_sram_wr_addr(input_sram_wr_addr),.input_sram_rd_addr(input_sram_rd_addr),
            .input_sram_data(input_sram_data),
            .bias_rf_en(bias_rf_en),.bias_rf_wr_en(bias_rf_wr_en),

            .bias_rf_wr_addr(bias_rf_wr_addr),
            .bias_rf_rd_addr(bias_rf_rd_addr),
            .bias_rf1_wr_data(bias_rf1_wr_data),.bias_rf2_wr_data(bias_rf2_wr_data),
            .bias_rf3_wr_data(bias_rf3_wr_data),.bias_rf4_wr_data(bias_rf4_wr_data),

            .kernel_rf_en(kernel_rf_en),.kernel_rf_wr_en(kernel_rf_wr_en),
            .kernel_rf_wr_addr(kernel_rf_wr_addr),
            .kernel1_rf_rd_addr(kernel1_rf_rd_addr),
            .kernel2_rf_rd_addr(kernel2_rf_rd_addr),
            .kernel3_rf_rd_addr(kernel3_rf_rd_addr),
            .kernel4_rf_rd_addr(kernel4_rf_rd_addr),
            .kernel1_rf_wr_data(kernel1_rf_wr_data),.kernel2_rf_wr_data(kernel2_rf_wr_data),
            .kernel3_rf_wr_data(kernel3_rf_wr_data),.kernel4_rf_wr_data(kernel4_rf_wr_data),

            .ps_sram_en(ps_sram_en),.ps_sram_rst_en(ps_sram_rst_en),
            .ps_sram_addr(ps_sram_addr),
            .result1(result1),.result2(result2),.result3(result3),.result4(result4)
            );
    //
    //---------------------------------------------------------------

//---------------------------------------------------------------------------------------Take out the color image(cat) of RGB----------------------------------------------
    //---------------------------------------------------------------
    //This initial block write the pixel 
    //---------------------------------------------------------------
    initial begin
        clk <= 1'b1;

        reset <= 1'b1;
        #(`period+(`period/2));
        reset <= 1'b0;

		R_resize<=0;
		G_resize<=0;
		B_resize<=0;

        input_sram_en = 1'b1;
        input_sram_wr_en = 0;
        input_sram_rd_addr = 0;

		i<=0;
		#(`period);
        input_sram_en = 1'b0;
		//---------------------------------------------------------------
		//Resize  the 224x224 to 56x56
	    for(idx = 0; idx <`cat56_size; idx = idx+1) begin						
			for(jdx = (0+4*(idx/56)); jdx <(4+4*(idx/56)); jdx = jdx+1) begin
				for(kdx = (0+4*i); kdx <(4+4*i); kdx = kdx+1) begin
					R_resize <= R_resize + img_data[(kdx+(jdx*224))*3 + offset + 2];
					G_resize <= G_resize + img_data[(kdx+(jdx*224))*3 + offset + 1];
					B_resize <= B_resize + img_data[(kdx+(jdx*224))*3 + offset + 0];
					#(`period);		
				end		
			end

            img_data_56[idx/56][idx%56][0] <= R_resize/16;
            img_data_56[idx/56][idx%56][1] <= G_resize/16;
            img_data_56[idx/56][idx%56][2] <= B_resize/16;
	
			R_56x56 <=R_resize/16;	//Take  R_56x56 as input 
			G_56x56 <=G_resize/16;	//Take  G_56x56 as input 
			B_56x56 <=B_resize/16;	//Take  B_56x56 as input 
			#(`period);
			
			//write cat56.bmp
			$fwrite(img_out, "%c%c%c",B_56x56[7:0] , G_56x56[7:0], R_56x56[7:0]);
			if(i==55)  i<=0;
			else i<=i+1;
			#(`period/2);
			R_resize <=0;
			G_resize <=0;
			B_resize <=0;
			#(`period/2);
        end	
        // ------------------------------ Image Padding ------------------------------
        input_sram_en = 1'b0;
        input_sram_wr_en = 0;

        for(img_ch=0;img_ch<3;img_ch=img_ch+1)begin
            for(img_h=0;img_h<58;img_h=img_h+1)begin
                for(img_w=0;img_w<58;img_w=img_w+1)begin
                    img_data_56_padding[img_h][img_w][img_ch] = 0;
                end
            end
        end
        for(img_ch=0;img_ch<3;img_ch=img_ch+1)begin
            for(img_h=0;img_h<56;img_h=img_h+1)begin
                for(img_w=0;img_w<56;img_w=img_w+1)begin
                    img_data_56_padding[img_h+1][img_w+1][img_ch] = img_data_56[img_h][img_w][img_ch];
                end
            end
        end
        for(img_ch=0;img_ch<3;img_ch=img_ch+1)begin
            for(img_h=0;img_h<58;img_h=img_h+1)begin
                for(img_w=0;img_w<58;img_w=img_w+1)begin
                    input_sram_wr_addr = (img_ch*58*58)+(img_h*58)+img_w;
                    input_sram_data = img_data_56_padding[img_h][img_w][img_ch];
                    #(`period);
                end
            end
        end

        input_sram_wr_en = 1;
        #(`period);
        // ----------------------------------------------------------------------------
        $display("----------- Start ! -------------");
        for(round_counter=0;round_counter<16;round_counter=round_counter+1)begin
            ps_sram_en = 0;
            ps_sram_addr =0;
            ps_sram_rst_en = 1;
            for(ps_sram_rst=0;ps_sram_rst<4096;ps_sram_rst=ps_sram_rst+1)begin
                ps_sram_addr = ps_sram_rst;
                #(`period);
            end
            ps_sram_rst_en = 0;
            bias_rf_en = 0;
            bias_rf_rd_addr = round_counter;
            #(`period);
            $display("Running %d Round ......",round_counter+1);
            bias_rf_en = 1;
            for(kernel_counter=0;kernel_counter<3;kernel_counter=kernel_counter+1)begin
                reset = 1;
                #(`period);
                reset = 0;
                for(kernel_pix=0;kernel_pix<9;kernel_pix=kernel_pix+1)begin
                    kernel_rf_en = 0;
                    kernel1_rf_rd_addr = (round_counter*27)+(9*kernel_counter)+kernel_pix;
                    kernel2_rf_rd_addr = (round_counter*27)+(9*kernel_counter)+kernel_pix;
                    kernel3_rf_rd_addr = (round_counter*27)+(9*kernel_counter)+kernel_pix;
                    kernel4_rf_rd_addr = (round_counter*27)+(9*kernel_counter)+kernel_pix;
                    //$display("Kernel %d %d :%h",kernel_counter,kernel4_rf_rd_addr,kernel4_rf_rd_data);
                    #(`period);
                    kernel_rf_en = 1;
                end
                for(pix_idx=0;pix_idx<3364;pix_idx=pix_idx+1)begin
                    input_sram_rd_addr = 3364*kernel_counter+pix_idx;
                    ps_sram_addr = pix_idx;
                    #(`period);
                end
            end
            counter = 0;
            for(write_out=0;write_out<3364;write_out=write_out+1)begin
                ps_sram_addr = write_out + 1;
                if(write_out > 58 && write_out <3305 && write_out % 58 != 0 && write_out % 58 != 57)begin
                    $fwrite(layer1_img_handle[4*round_counter+0],"%c%c%c",result1[11:4],result1[11:4],result1[11:4]);
                    $fwrite(layer1_img_handle[4*round_counter+1],"%c%c%c",result2[11:4],result2[11:4],result2[11:4]);
                    $fwrite(layer1_img_handle[4*round_counter+2],"%c%c%c",result3[11:4],result3[11:4],result3[11:4]);
                    $fwrite(layer1_img_handle[4*round_counter+3],"%c%c%c",result4[11:4],result4[11:4],result4[11:4]);
                end
                #(`period);
            end
             #(`period);
        end
        $fclose(img_in);
        $fclose(img_out);
        $finish;
    end

    //---------------------------------------------------------------
    //This initial block read the pixel 
    //---------------------------------------------------------------
    initial begin
        img_in  = $fopen(`path_img_in, "rb");
        img_out = $fopen(`path_img_out, "wb");

        $fread(img_data, img_in);

        for(i=0;i<64;i=i+1)begin
            if (i < 10) begin
                digit1 = i + "0";
                file_name1 = {`path_res_img, "0", digit1, ".bmp"};
            end else begin
                digit1 = (i / 10) + "0";
                digit2 = (i % 10) + "0";
                file_name1 = {`path_res_img, digit1, digit2, ".bmp"};
            end
            layer1_img_handle[i] = $fopen(file_name1, "wb"); // 以二進制模式打開
        end

        for(j=0;j<64;j=j+1)begin
            for(header=0;header<54;header=header+1)begin
			if(header==18 || header==22) 
				$fwrite(layer1_img_handle[j], "%c", 8'd56);
			else 
                $fwrite(layer1_img_handle[j],"%c",img_data[header]);
            end
        end

        img_w   = {img_data[21],img_data[20],img_data[19],img_data[18]};
        img_h   = {img_data[25],img_data[24],img_data[23],img_data[22]};
        offset  = {img_data[13],img_data[12],img_data[11],img_data[10]};
		
        for(header = 0; header < 54; header = header + 1) begin	//output header -> 56x56
			if(header==18 || header==22) 
				$fwrite(img_out, "%c", 8'd56);
			else 
				$fwrite(img_out, "%c", img_data[header]);
        end
    end
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    initial begin                                   // Bias Register file
        $readmemh(`path_bias,bias_data);
        #(`period);
        bias_rf_rd_addr = 0;
        bias_rf_en = 0;
        bias_rf_wr_en = 0;
        for(rf_i=0;rf_i<16;rf_i=rf_i+1)begin
            bias_rf_wr_addr = rf_i;
            bias_rf1_wr_data = bias_data[4*rf_i+0];
            bias_rf2_wr_data = bias_data[4*rf_i+1];
            bias_rf3_wr_data = bias_data[4*rf_i+2];
            bias_rf4_wr_data = bias_data[4*rf_i+3];
            #(`period);
        end
        bias_rf_wr_en = 1;
        bias_rf_en = 1;
    end

    initial begin                                   // Kernel Register File
        $readmemh(`path_kernel,kernel_data);
        #(`period);
        kernel_rf_en = 0;
        kernel_rf_wr_en = 0;
        kernel1_rf_rd_addr = 0;
        kernel2_rf_rd_addr = 0;
        kernel3_rf_rd_addr = 0;
        kernel4_rf_rd_addr = 0;
        for(kernel_i=0;kernel_i<16;kernel_i=kernel_i+1)begin
            //#(`period);
            for(kernel_j=0;kernel_j<27;kernel_j=kernel_j+1)begin
                kernel_rf_wr_addr = (kernel_i*27)+kernel_j;
                kernel1_rf_wr_data = kernel_data[108*kernel_i+kernel_j];
                kernel2_rf_wr_data = kernel_data[108*kernel_i+kernel_j+27];
                kernel3_rf_wr_data = kernel_data[108*kernel_i+kernel_j+54];
                kernel4_rf_wr_data = kernel_data[108*kernel_i+kernel_j+81];
                #(`period);
            end
        end
        kernel_rf_wr_en = 1;
        kernel_rf_en = 1;
    end
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    always begin
		#(`period/2.0) clk <= ~clk;
	end
    initial begin
		$sdf_annotate (`path_sdf, U1);
	end
endmodule
