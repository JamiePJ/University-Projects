import os
import pandas as pd
from PIL import Image, ImageDraw, ImageFilter, ImageOps, ImageEnhance

# function for saving class labels only from one file
def save_class_labels_from_file(file):    
    class_labels = []
    with open(file, "r") as text:
        # split file into lines
        lines = text.readlines()
        # clean "/n" from each line
        clean_lines = [line.strip("/n") for line in lines]
        # create list of values in each line
        list_values = [line.split() for line in clean_lines]
        # add class labels to list
        for value in list_values:
            class_labels.append(int(value[0]))
        text.close()
    return class_labels

# function for saving class labels from directory of label files, return list of all 
def save_class_labels_from_directory(directory):
    class_labels = [save_class_labels_from_file(directory+file) for file in os.listdir(directory)]
    file_class_labels = [label for list in class_labels for label in list]
    return file_class_labels

# function to create dataframe from class labels and class names dict
def create_class_labels_df(class_labels, class_names_dict):
    classes_df = pd.DataFrame(data=class_labels, index=None, columns=["class_label_int"])
    classes_df["class_label_int"].astype("int")
    classes_df["class_label_txt"] = classes_df["class_label_int"].astype("int")
    classes_df.replace({"class_label_txt": class_names_dict}, inplace=True)
    return classes_df

# function for saving coordinates only from one file
def save_coords_from_file(file):
    with open(file, "r") as text:
        # split file into lines
        lines = text.readlines()
        # clean "/n" from each line
        clean_lines = [line.strip("/n") for line in lines]
        # create list of values in each line
        list_values = [line.split() for line in clean_lines]
        # add coords to list
        coords = [[float(x) for x in coord_list] for coord_list in list_values]
        coords = [x[1:] for x in coords]
        # close file
        text.close()
    return coords

# function to return class labels and coordinates from one file
def save_labels_coords_from_file(file):
    class_labels = []
    with open(file, "r") as text:
        # split file into lines
        lines = text.readlines()
        # clean "/n" from each line
        clean_lines = [line.strip("/n") for line in lines]
        # create list of values in each line
        list_values = [line.split() for line in clean_lines]
        # add class labels to list
        for value in list_values:
            class_labels.append(int(value[0]))

        # add coords to list
        coords = [[float(x) for x in coord_list] for coord_list in list_values]
        coords = [x[1:] for x in coords]
        # close file
        text.close()
    return class_labels, coords

# function for calculating bounding box coords for drawing (using polygon formatting)
def calc_bound_box_coords_for_drawing(bound_box_det_list, img_width, img_height, flip=False, reverse=False):
    x_min = (bound_box_det_list[0] - (bound_box_det_list[2]/2))*img_width
    x_max = (bound_box_det_list[0] + (bound_box_det_list[2]/2))*img_width
    y_min = (bound_box_det_list[1] - (bound_box_det_list[3]/2))*img_height
    y_max = (bound_box_det_list[1] + (bound_box_det_list[3]/2))*img_height
    if flip:
        # flip y coord
        y_min = (img_height/2) - (y_min-(img_height/2))
        y_max = (img_height/2) - (y_max-(img_height/2))
    if reverse:
        # reverse x coord
        x_min = (img_width/2) - (x_min-(img_width/2))
        x_max = (img_width/2) - (x_max-(img_width/2))
    return ((x_min, y_max), (x_max, y_max), (x_max, y_min), (x_min, y_min))

# function for creating coordinates for drawing polygons on image
def calc_polygon_coords_for_drawing(polygon_coords, img_width, img_height, flip=False, reverse=False):
    x_coords = [polygon_coords[i]*img_width for i in range(0, len(polygon_coords), 2)]
    y_coords = [polygon_coords[i]*img_height for i in range(1, len(polygon_coords), 2)]
    if flip:
        y_coords = [(img_height/2) - (coord - (img_height/2)) for coord in y_coords]
    if reverse:
        x_coords = [(img_width/2) - (coord - (img_width/2)) for coord in x_coords]
    polygon_tuple_coords = tuple(zip(x_coords, y_coords))
    return polygon_tuple_coords

# function for image transformations
def image_transform(original_image, transform=None, flip_image=False, reverse_image=False):
    if transform is None:
        transformed_image = original_image
    if transform == "blur":
        transformed_image = original_image.filter(ImageFilter.BLUR)
    if transform == "greyscale":
        transformed_image = ImageOps.grayscale(original_image)
    if transform == "increase_brightness":
        brightness_filter = ImageEnhance.Brightness(original_image)
        transformed_image = brightness_filter.enhance(3.0) 
    if transform == "decrease_brightness":
        brightness_filter = ImageEnhance.Brightness(original_image)
        transformed_image = brightness_filter.enhance(0.25) 
    if transform == "increase_contrast":
        contrast_filter = ImageEnhance.Contrast(original_image)
        transformed_image = contrast_filter.enhance(3.0)
    if transform == "decrease_contrast":
        contrast_filter = ImageEnhance.Contrast(original_image)
        transformed_image = contrast_filter.enhance(0.25)
    if flip_image:
        transformed_image = transformed_image.transpose(Image.FLIP_TOP_BOTTOM)
    if reverse_image:
        transformed_image = transformed_image.transpose(Image.FLIP_LEFT_RIGHT)
    return transformed_image

# function for calculating each set of coordinates from a label file - incorporates the bound box & polygon functions
def calc_coords(coords_list, flip_coords=False, reverse_coords=False):
        if len(coords_list) == 4:
            coords = recalc_bound_box(coords_list, flip=flip_coords, reverse=reverse_coords)
        else:
            coords = recalc_polygon(coords_list, flip=flip_coords, reverse=reverse_coords)
        return coords

# function to recalculate label file values after image transformation for bounding boxes (normalised, not for drawing)
def recalc_bound_box(bound_box_det_list, flip=False, reverse=False):
    if flip:
        # flip centre y value
        coords = [bound_box_det_list[0], 0.5 - (bound_box_det_list[1]-0.5), bound_box_det_list[2], bound_box_det_list[3]]
    if reverse:
        # flip centre x value
        coords = [0.5 - (bound_box_det_list[0]-0.5), bound_box_det_list[1],bound_box_det_list[2], bound_box_det_list[3]]
    return coords

# function to recalculate label file values after image transformation for polygons (normalised, not for drawing)
def recalc_polygon(polygon_coords_list, flip=False, reverse=False):
    x_coords = [polygon_coords_list[i] for i in range(0, len(polygon_coords_list), 2)]
    y_coords = [polygon_coords_list[i] for i in range(1, len(polygon_coords_list), 2)]
    if flip:
        # flip y values
        y_coords = [0.5 - (coord - 0.5) for coord in y_coords]
    if reverse:
        # flip x values
        x_coords = [0.5 - (coord - 0.5) for coord in x_coords]
    coords_pairs = list(zip(x_coords, y_coords))
    coords = [coord for pair in coords_pairs for coord in pair]
    return coords

# function for creating df for a labels directory
def create_df_from_labels_dir(labels_directory, image_width, image_height):
    # save all class label and bbox details
    all_class_labels = []
    all_centre_x = []
    all_centre_y = []
    all_widths = []
    all_heights = []
    for file_name in os.listdir(labels_directory):
        file_class_labels, file_bbox_coords = transf_func.save_labels_coords_from_file(f"{labels_directory}{file_name}")
        centre_x = [coord[0]*image_width for coord in file_bbox_coords]
        centre_y = [-coord[1]*image_height for coord in file_bbox_coords]
        bbox_width = [coord[2]*image_width for coord in file_bbox_coords]
        bbox_height = [coord[3]*image_height for coord in file_bbox_coords]
        all_class_labels.append(file_class_labels)
        all_centre_x.append(centre_x)
        all_centre_y.append(centre_y)
        all_widths.append(bbox_width)
        all_heights.append(bbox_height)
    
    # unpack lists
    unpacked_class_labels = [label for list in all_class_labels for label in list]
    unpacked_centre_x = [x for list in all_centre_x for x in list]
    unpacked_centre_y = [y for list in all_centre_y for y in list]
    unpacked_widths = [width for list in all_widths for width in list]
    unpacked_heights = [height for list in all_heights for height in list]
    
    # merge unpacked lists
    merged_lists = list(zip(unpacked_class_labels, unpacked_centre_x, unpacked_centre_y, unpacked_widths, unpacked_heights))
    merged_lists[0]
    
    # create DataFrame, add bbox area column
    bbox_df = pd.DataFrame(merged_lists, columns=["class_label", "centre_x", "centre_y", "width", "height"])
    bbox_df["bbox_area"] = bbox_df["width"] * bbox_df["height"]
    
    # rename class labels as vehicle types
    class_names_dict = {0:'Articulated', 1:'Bus', 2:'Car', 3:'Coach', 4:'LGV', 5:'Rigid 2 Axle', 6:'Rigid 3 Axle', 7:'Rigid 4 Axle', 8:'Taxi'}
    bbox_df["class_label"].replace(class_names_dict, inplace=True)
    return bbox_df