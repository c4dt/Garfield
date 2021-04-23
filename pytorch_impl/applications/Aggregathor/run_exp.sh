#!/bin/bash

ps_names="servers"
worker_names="workers"
num_wrk=1000			#The upper bound on the number of workers in any deployment
fw=0
fps=0
iter=100000			#100000
dataset='cifar10'
model='resnet50'			#'resnet18'
optimizer='sgd'
batch=25
loss='cross-entropy'
lr=0.2
gar='average'
master=''
num_ps=0
while read p; do
    	num_ps=$((num_ps+1))
	if [ $num_ps -eq  1 ]
  	then
     		master=$p
  	fi
done < $ps_names

num_workers=0
while read p; do
	num_workers=$((num_workers+1))
	if [ $num_workers -eq $num_wrk ]
  	then
     		break
  	fi
done < $worker_names

pwd=`pwd`
main=$( realpath ./trainer.py --relative-base $( git rev-parse --show-toplevel ) )
node_base=./Garfield
#CUDAHOSTCXX=/usr/bin/gcc-5
common=". ./Garfield/pytorch_impl/venv_pytorch/bin/activate && python3 ${node_base}/${main} --master $master --num_iter $iter --dataset $dataset --model $model --batch $batch --loss $loss"
common="$common --optimizer $optimizer --opt_args '{\"lr\":\"$lr\",\"momentum\":\"0.9\",\"weight_decay\":\"0.0005\"}' --num_ps $num_ps --num_workers $num_workers --fw $fw --fps $fps --gar $gar"
i=0
while read p; do
	cmd="$common --rank $i"
	ssh -i ~/.vagrant.d/insecure_private_key vagrant@$p "$cmd" < /dev/tty &
        echo "running $cmd on $p"
	i=$((i+1))
done < $ps_names

count_workers=0
while read p; do
        cmd="$common --rank $i"
        ssh -i ~/.vagrant.d/insecure_private_key vagrant@$p "$cmd" < /dev/tty &
        echo "running $cmd on $p"
        i=$((i+1))
	count_workers=$((count_workers+1))
        if [ $count_workers -eq $num_wrk ]
        then
                break
        fi
done < $worker_names
