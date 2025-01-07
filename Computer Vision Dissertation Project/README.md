# Vehicle Detection with YOLOv8x and YOLOv10x
***
Welcome to my MSc Data Science Dissertation project on vehicle detection using two versions of YOLO model. The pretrained YOLO models were trained with transfer learning on a custom dataset of vehicle and road images.

This project is split into two folders - "EDA, Image Transformation and Model Comparison" and "Model Training, Grid Search and Validation". 
Files in "EDA, Image Transformation and Model Comparison" were run on-premise using my personal machine, and the files in "Model Training, Grid Search and Validation" were run on Google Colab to utilise the GPU for processing.

## Folder Structure
--------------------------------------------------------------------------------
### "EDA, Image Transformation and Model Comparison" folder contents and descriptions:
image_transformation_functions.py - collection of functions used in the other notebooks for processing image and annotation files.\
1_Original Dataset EDA.ipynb - exploratory data analysis conducted on the original dataset provided by the business.\
2_Expanded Dataset EDA.ipynb - exploratory data analysis conducted on the dataset after additional images were sourced.\
3_Image Transformation.ipynb - transformations applied to every training image to increase the dataset size.\
4_Initial Model Validation.ipynb - validation and analysis of first model trained on expanded dataset.\
5_New Dataset EDA Pre-Augmentation.ipynb - exploratory data analysis conducted on the new dataset after further images were sourced.\
6_New Dataset Model Validation.ipynb - validation of model trained on the new dataset.\
7_Best Hyperparameters Compared to Defaults.ipynb - validation and comparative analysis of the models trained with optimal and default hyperparameters.\
8_Final Models Comparison.ipynb - validation and comparative analysis of the final models.

--------------------------------------------------------------------------------
### "Model Training, Grid Search and Validation" folder contents and descriptions:
1_initial_model_training_and_regularisation_experiments.ipynb - initial model training and validation, regularisation experiments with model training and validation.\
2_initial_model_regularisation_models_validation.ipynb - further validation of initial and regularisation experiment models.\
3_new_dataset_model_training_validation.ipynb - training and validation of first model trained on new dataset.\
4_yolov8_hyperparameter_tuning.ipynb - YOLOv8x hyperparameter tuning using grid search. All tested YOLOv8x hyperparameter combinations are trained in this file. \
5_yolov10_hyperparameter_tuning.ipynb - YOLOv10 hyperparameter tuning using grid search. All tested YOLOv10x hyperparameter combinations are trained in this file. \
6_yolov8_gridsearch_validation.ipynb - Validation of each YOLOv8x grid search model. \
7_yolov10_gridsearch_validation.ipynb - Validation of each YOLOv10x grid search model.\
8_model_training_best_hyperparameters.ipynb - Final model training using the optimal hyperparameters established during grid search.\
9_final_models_prediction.ipynb - Predictions on sample video using both final models.
