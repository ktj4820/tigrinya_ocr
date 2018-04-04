#!/bin/bash

# commands to train and run Tesseract OCR

tesseract ~/tigrinya_ocr/eval/tir_testdata.pdf ~/tigrinya_ocr/tessdata/fast \
  -l tir --oem 1 --tessdata-dir ~/tigrinya_ocr/tessdata/fast --psm 3

combine_lang_model --input_unicharset ~/tigrinya_ocr/tir/Ethiopic.unicharset \
  --script_dir ~/tigrinya_ocr/tir/ --output_dir ~/training --lang tir \
  --words ~/tigrinya_ocr/tir/tir.wordlist --puncs ~/tigrinya_ocr/tir/tir.punc --numbers ~/tigrinya_ocr/tir/tir.numbers \
  --version_str 0.0.1

tesseract ~/tigrinya_ocr/eval/tir_testdata.pdf ~/tigrinya_ocr/eval/tir_init_output \
  -l tir --oem 1 --tessdata-dir ~/tigrinya_ocr/tir/tir_best.traineddata --psm 3

uni2asc < ~/tigrinya_ocr/eval/tir_init_output.txt > ~/training/init_output_ascii.txt
uni2asc < ~/tigrinya_ocr/eval/tir_groundtruth.txt > ~/training/groundtruth_ascii.txt
accuracy ~/tigrinya_ocr/eval/tir_groundtruth.txt ~/tigrinya_ocr/eval/tir_init_output.txt

lstmtraining --model_output /path/to/output [--max_image_MB 6000] \
  --continue_from /path/to/existing/model \
  --traineddata /path/to/original/traineddata \
  [--perfect_sample_delay 0] [--debug_interval 0] \
  [--max_iterations 0] [--target_error_rate 0.01] \
  --train_listfile /path/to/list/of/filenames.txt

lstmeval --model ~/training/impact_checkpoint \
  --traineddata ~/tigrinya_ocr/tir/tir_best.traineddata \
  --eval_listfile ~/tesstutorial/engeval/eng.training_files.txt



lstmtraining  \
   -U ~/tesstutorial/nyd/eng.unicharset \
  --train_listfile ~/tesstutorial/nyd/eng.training_files.txt \
  --script_dir ../langdata   \
  --append_index 5 --net_spec '[Lfx256 O1c105]' \
  --continue_from ~/tesstutorial/eng_from_nyd/eng.lstm \
  --model_output ~/tesstutorial/eng_from_nyd/nyd \
  --debug_interval -1 \
  --target_error_rate 0.01
   
lstmtraining \
  --continue_from ~/tesstutorial/eng_from_nyd/nyd_checkpoint \
  --model_output ~/tesstutorial/eng_from_nyd/nyd.lstm \
  --stop_training

cp ../tessdata/eng.traineddata ~/tesstutorial/eng_from_nyd/nyd.traineddata
   
combine_tessdata -o ~/tesstutorial/eng_from_nyd/nyd.traineddata \
  ~/tesstutorial/eng_from_nyd/nyd.lstm \
  ~/tesstutorial/nyd/eng.lstm-number-dawg \
  ~/tesstutorial/nyd/eng.lstm-punc-dawg \
  ~/tesstutorial/nyd/eng.lstm-word-dawg 
 