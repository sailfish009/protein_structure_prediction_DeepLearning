#Script called on hyperparameter tuning model class
#Edit script with desired hyperparameters
#!/bin/bash

#Hyperparameters for CNN component of model
CONV1_FILTERS=64
CONV2_FILTERS=128
CONV3_FILTERS=256
WINDOW_SIZE=7
CONV2D_DROPOUT=0.5
KERNEL_REGULARIZER='l2'
POOL_SIZE=2

#Hyperparameters for RNN component of model
RECURRENT_LAYER1=400
RECURRENT_LAYER2=300
RECURRENT_DROPOUT=0.5
RECURRENT_RECURRENT_DROPOUT=0.5
AFTER_RECURRENT_DROPOUT=0.5
BIDIRECTION=True
RECURRENT_LAYER='lstm'

#Hyperparameters for DNN component of model
DENSE_1=128
DENSE_2=64
DENSE_3=32
DENSE_4=16
DENSE_DROPOUT=0.5

#Model hyperparameters
OPTIMIZER="adam"
LEARNING_RATE=0.0003
EPOCHS=10
BATCH_SIZE=42


BUCKET_NAME="keras-python-models-2"
JOB_NAME="$RECURRENT_LAYER""_hp_config_model_$(date +"%Y%m%d_%H%M%S")"
JOB_DIR="gs://keras-python-models"
LOGS_DIR="$JOB_DIR""/logs/tensorboard/hp_tuning_$(date +"%Y%m%d_%H%M")"

PACKAGE_PATH="training/"
STAGING_BUCKET="gs://keras-python-models-2/job_logs"
HP_CONFIG="training/training_utils/gcp_training_config.yaml"
MODULE="training.psp_rnn_gcp_hpconfig"
RUNTIME_VERSION="2.1"
PYTHON_VERSION="3.7"
REGION="us-central1"

echo "Hyperparameter tuning for LSTM model"
echo "Job Details..."
echo "Job Name: $JOB_NAME"
echo "Logs and model will be stored to $BUCKET_NAME bucket"
echo "Region: $REGION"
echo ""
echo "Hyperparameters..."
echo ""
echo "GCP Machine Type Parameters..."

if !(pip --version == '20.2.1')
then
  echo "Updating pip to latest version"
  sudo -H pip3 install --upgrade pip
else
  echo "Pip up-to-date"
fi

#Function to parse config file
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}
eval $(parse_yaml training/hptuning_config.yaml)

#submit packaged training job to Gcloud Ai-Platform
gcloud ai-platform jobs submit training $JOB_NAME \
    --package-path $PACKAGE_PATH \
    --module-name $MODULE \
    --staging-bucket $STAGING_BUCKET \
    --runtime-version $RUNTIME_VERSION \
    --python-version $PYTHON_VERSION  \
    --job-dir $JOB_DIR \
    --region $REGION \
    --config $HP_CONFIG \
    -- \  #user-defined args below here
    --conv1_filters $CONV1_FILTERS \
    --conv2_filters $CONV2_FILTERS \
    --conv3_filters $CONV3_FILTERS \
    --window_size $WINDOW_SIZE \
    --kernel_regularizer $KERNEL_REGULARIZER \
    --pool_size $POOL_SIZE \
    --conv2d_dropout $CONV2D_DROPOUT \
    --recurrent_layer1 $RECURRENT_LAYER1 \
    --recurrent_layer2 $RECURRENT_LAYER2 \
    --recurrent_dropout $RECURRENT_DROPOUT \
    --after_recurrent_dropout $AFTER_RECURRENT_DROPOUT \
    --recurrent_recurrent_dropout $RECURRENT_RECURRENT_DROPOUT \
    --optimizer $OPTIMIZER \
    --learning_rate $LEARNING_RATE \
    --bidirection $BIDIRECTION \
    --recurrent_layer $RECURRENT_LAYER \
    --dense_1 $DENSE_1 \
    --dense_2 $DENSE_2 \
    --dense_3 $DENSE_3 \
    --dense_4 $DENSE_4 \
    --epochs $EPOCHS \
    --batch_size $BATCH_SIZE \
    --logs_dir $LOGS_DIR


echo "To view model progress through tensorboard in Google Cloud shell or terminal execute..."
echo "tensorboard --logdir=$LOGS_DIR --port=8080"
echo "If in cloud shell, then click on the web preview option "
#visualise model results on TensorBoard
# tensorboard --logdir "gs://keras-python-models/logs/tensorboard"

#Stream logs on command line
#gcloud ai-platform jobs stream-logs $JOB_NAME


model_hyperparameter_file="model_hyperparameters_$(date +"%Y%m%d_%H").txt"

# if [ -f "$model_hyperparameter_file" ]
# then
#Working##
# function output_parameter_text {
#
#       model_text_summary=$(printf "Hyperparameters for PSP model...\n \nJob Details:
#       \nAi-Platform Job Name: $JOB_NAME \nAi-Platform Job Dir: $JOB_DIR\nStaging Bucket: $STAGING_BUCKET \nRegion:  $REGION\nRuntime Version: $RUNTIME_VERSION\nPython Version: $PYTHON_VERSION
#       \nModel Hyperparameters:\n
#       \nConv2D Layer 1 filters: $CONV2D_LAYER1_FILTERS\nConv2D Layer 2 filters: $CONV2D_LAYER2_FILTERS\nConv2D Activation Function: $CONV2D_ACTIVATION\nConv2D Dropout: $CONV2D_DROPOUT\nRecurrent Layer: $RECURRENT_LAYER\nBidirection: $BIDIRECTION\nRecurrent Layer Dropout: $RECURRENT_DROPOUT\nRecurrent Layer Recurrent Dropout: $RECURRENT_RECURRENT_DROPOUT\nAfter Recurrent Layer Dropout: $AFTER_RECURRENT_DROPOUT\nOptimizer: $OPTIMIZER\nLearning Rate: $LEARNING_RATE\nEpochs: $EPOCHS\nBatch Size: $BATCH_SIZE")
#
#       echo "$model_text_summary" > $model_hyperparameter_file
#       echo "${model_text_summary}"
# }
#
# echo "After func"
# OUTPUT=$(output_parameter_text)
# echo "${OUTPUT}"
# output_parameter_text
# fi
