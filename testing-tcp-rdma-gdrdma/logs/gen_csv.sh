#!/bin/bash

grep -v "#kernel" TCP/nstat_post_npods2_nprocs4_numiter10_gradaccum1_bs32_seq1024_totalbs262144_profile0_modeld12_typeTCP_runidmay18_protoscan | awk 'BEGIN{"name,count"} {printf($1","$2"\n")}' > tcp.csv

grep -v "#kernel" RDMA/nstat_post_npods2_nprocs4_numiter10_gradaccum1_bs32_seq1024_totalbs262144_profile0_modeld12_typeRDMA_runidmay18_protoscan | awk 'BEGIN{"name,count"} {printf($1","$2"\n")}' > rdma.csv

grep -v "#kernel" GDR/nstat_post_npods2_nprocs4_numiter10_gradaccum1_bs32_seq1024_totalbs262144_profile0_modeld12_typeGDR_runidmay18_protoscan | awk 'BEGIN{"name,count"} {printf($1","$2"\n")}' > gdr.csv
