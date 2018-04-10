#!/bin/bash
# commands to train and run Tesseract OCR

dpkg --listfiles tesseract-ocr-eng
export TESSDATA_PREFIX=/usr/share/tesseract-ocr/4.00/tessdata

# convert a pdf into tiff files, one per page
convert -density 300 tir_testdata.pdf -depth 8 -background white \
  -flatten +matte tir_testdata-%02d.tiff

# try tesseract for the generated tiff files
# repeat for fast, int, best
for i in {00..18}
do
  tesseract ~/tigrinya_ocr/eval/tir_testdata-$i.tiff ~/tigrinya_ocr/tessdata/best/tir_eval-$i \
  -l tir --oem 1 --tessdata-dir ~/tigrinya_ocr/tessdata/best --psm 3
done

# evaluate, need to format ground truth txt files
uni2asc < ~/tigrinya_ocr/tessdata/best/tir_eval-00.txt > ~/tigrinya_ocr/eval/tir_testdata_ascii-00.txt
uni2asc < ~/tigrinya_ocr/eval/tir_groundtruth.txt > ~/tigrinya_ocr/eval/tir_groundtruth_ascii.txt
accuracy ~/tigrinya_ocr/eval/tir_groundtruth.txt ~/tigrinya_ocr/tessdata/best/tir_eval-00.txt
accuracy ~/tigrinya_ocr/eval/tir_groundtruth_ascii.txt ~/tigrinya_ocr/eval/tir_testdata_ascii-00.txt

# create a new tir.traineddata
combine_lang_model --input_unicharset ~/tigrinya_ocr/tir/Ethiopic.unicharset \
  --script_dir ~/tigrinya_ocr/tir --output_dir ~/tigrinya_ocr/training --lang tir \
  --words ~/tigrinya_ocr/tir/tir.wordlist --puncs ~/tigrinya_ocr/tir/tir.punc --numbers ~/tigrinya_ocr/tir/tir.numbers \
  --version_str 0.0.1

# list fonts
fc-list | grep tir_fonts
text2image --list_available_fonts --fonts_dir /usr/local/share/fonts/tir_fonts

# update language specific fonts under AMHARIC_FONTS
sudo vi /usr/share/tesseract-ocr/language-specific.sh

# generate test data
/usr/share/tesseract-ocr/tesstrain.sh \
  --fontlist "Abyssinica SIL" "Abyssinica SIL Sebatbeit" "Abyssinica SIL Ximtanga" "Code2003 Medium" "Ethiopia Jiret" "Ethiopic Fantuwua" "Ethiopic Hiwua" "Ethiopic Tint" "Ethiopic WashRa Bold, Bold" "Ethiopic WashRa SemiBold, Bold" "Ethiopic Wookianos" "Ethiopic Yebse" "Ethiopic Zelan" "GF Zemen Unicode" "Ethiopic Yigezu Bisrat Goffer" "Ethiopic Yigezu Bisrat Gothic" \
  --fonts_dir /usr/local/share/fonts/tir_fonts \
  --lang tir --langdata_dir ~/tigrinya_ocr \
  --output_dir ~/tigrinya_ocr/generated \
  --overwrite --linedata_only --exposures 0 --noextract_font_properties \
  --training_text ~/tigrinya_ocr/eval/tir_groundtruth.txt \
  --wordlist ~/tigrinya_ocr/tir/tir.wordlist \
  --tessdata_dir ~/tigrinya_ocr/training 

# for only 1 font
/usr/share/tesseract-ocr/tesstrain.sh \
  --fontlist "Abyssinica SIL" \
  --fonts_dir /usr/local/share/fonts/tir_fonts \
  --lang tir --langdata_dir ~/tigrinya_ocr/langdata \
  --output_dir ~/tigrinya_ocr/generated \
  --overwrite --linedata_only --exposures 0 --noextract_font_properties \
  --training_text ~/tigrinya_ocr/eval/tir_groundtruth.txt \
  --wordlist ~/tigrinya_ocr/langdata/tir/tir.wordlist \
  --tessdata_dir ~/tigrinya_ocr/training

# view generated images
gksudo nautilus --browser /tmp/tmp.wpk6QANxS5/tir
xdg-open /tmp/tmp.wpk6QANxS5/tir/tir.Abyssinica_SIL.exp0.tif

# create filnames file
ls -d $PWD/tigrinya_ocr/generated/*.lstmf > ~/tigrinya_ocr/generated/tir.training_files.txt

# evaluate model
lstmeval --model ~/tigrinya_ocr/langdata/tir/tir_best.traineddata \
  --eval_listfile ~/tigrinya_ocr/generated/tir.training_files.txt

lstmtraining --model_output ~/tigrinya_ocr/training \
  --continue_from ~/tigrinya_ocr/langdata/tir/tir_best.traineddata \
  --traineddata ~/tigrinya_ocr/langdata/tir/tir.traineddata \
  --train_listfile ~/tigrinya_ocr/generated/tir.training_files.txt \
  --max_image_MB 3000 &> ~/tigrinya_ocr/logs/try1.log
#  [--perfect_sample_delay 0] [--debug_interval 0] \
#  [--max_iterations 0] [--target_error_rate 0.01] \

lstmeval --model ~/tigrinya_ocr/training/checkpoint \
  --traineddata ~/tigrinya_ocr/langdata/tir/tir.traineddata \
  --eval_listfile ~/tigrinya_ocr/generated/tir.training_files.txt


export TESSDATA_PREFIX=/home/babraham/tigrinya_ocr/training
java -jar VietOCR.jar

 
