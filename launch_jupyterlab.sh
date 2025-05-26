module load python
source activate /project/bios26406/conda/ml4h

HOST_IP=`/sbin/ip route get 8.8.8.8 | awk '{print $7;exit}'`
echo $HOST_IP

jupyter-lab --no-browser --ip=$HOST_IP --port=15021
