// src/native/engine/android/java/com/nativecr/ImagePickerHelper.java

package com.nativecr;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.content.FileProvider;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

import android.Manifest;
import android.content.ContentResolver;
import android.database.Cursor;

public class ImagePickerHelper {
    private static final int REQUEST_IMAGE_CAPTURE = 1001;
    private static final int REQUEST_GALLERY_PICK = 1002;
    private static final int REQUEST_CAMERA_PERMISSION = 1003;
    private static final int REQUEST_STORAGE_PERMISSION = 1004;

    private static Activity currentActivity;
    private static ImagePickerCallback callback;
    private static String currentPhotoPath;
    private static int currentQuality = 90;
    private static int maxWidth = 0;
    private static int maxHeight = 0;

    public interface ImagePickerCallback {
        void onResult(String path, byte[] data, int width, int height, String mimeType, boolean success);
    }

    public static void init(Activity activity) {
        currentActivity = activity;
    }

    public static void setCallback(ImagePickerCallback cb) {
        callback = cb;
    }

    public static void pickImage(Activity activity, int source, int quality, int maxDim) {
        currentActivity = activity;
        currentQuality = quality;
        maxWidth = maxDim;
        maxHeight = maxDim;

        if (source == 0) { // Camera
            checkCameraPermissionAndLaunch();
        } else { // Gallery
            checkStoragePermissionAndLaunch();
        }
    }

    public static void takePhoto(Activity activity, int quality, int maxDim) {
        currentActivity = activity;
        currentQuality = quality;
        maxWidth = maxDim;
        maxHeight = maxDim;
        checkCameraPermissionAndLaunch();
    }

    private static void checkCameraPermissionAndLaunch() {
        if (ContextCompat.checkSelfPermission(currentActivity, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(currentActivity, new String[]{Manifest.permission.CAMERA}, REQUEST_CAMERA_PERMISSION);
            return;
        }
        launchCamera();
    }

    private static void checkStoragePermissionAndLaunch() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            // Android 13+ doesn't need storage permission for gallery
            launchGallery();
            return;
        }
        if (ContextCompat.checkSelfPermission(currentActivity, Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(currentActivity, new String[]{Manifest.permission.READ_EXTERNAL_STORAGE}, REQUEST_STORAGE_PERMISSION);
            return;
        }
        launchGallery();
    }

    private static void launchCamera() {
        Intent takePictureIntent = new Intent(MediaStore.ACTION_IMAGE_CAPTURE);
        if (takePictureIntent.resolveActivity(currentActivity.getPackageManager()) != null) {
            File photoFile = null;
            try {
                photoFile = createImageFile();
            } catch (IOException ex) {
                if (callback != null) {
                    callback.onResult(null, null, 0, 0, null, false);
                }
                return;
            }
            if (photoFile != null) {
                Uri photoURI = FileProvider.getUriForFile(currentActivity,
                        currentActivity.getPackageName() + ".fileprovider",
                        photoFile);
                takePictureIntent.putExtra(MediaStore.EXTRA_OUTPUT, photoURI);
                currentActivity.startActivityForResult(takePictureIntent, REQUEST_IMAGE_CAPTURE);
            }
        }
    }

    private static void launchGallery() {
        Intent pickPhotoIntent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        currentActivity.startActivityForResult(pickPhotoIntent, REQUEST_GALLERY_PICK);
    }

    private static File createImageFile() throws IOException {
        String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(new Date());
        String imageFileName = "JPEG_" + timeStamp + "_";
        File storageDir = currentActivity.getExternalFilesDir(Environment.DIRECTORY_PICTURES);
        File image = File.createTempFile(imageFileName, ".jpg", storageDir);
        currentPhotoPath = image.getAbsolutePath();
        return image;
    }

    public static void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (resultCode != Activity.RESULT_OK) {
            if (callback != null) {
                callback.onResult(null, null, 0, 0, null, false);
            }
            return;
        }

        if (requestCode == REQUEST_IMAGE_CAPTURE) {
            handleCameraResult();
        } else if (requestCode == REQUEST_GALLERY_PICK) {
            handleGalleryResult(data);
        }
    }

    private static void handleCameraResult() {
        if (currentPhotoPath != null) {
            File imgFile = new File(currentPhotoPath);
            if (imgFile.exists()) {
                processImage(currentPhotoPath);
                return;
            }
        }
        if (callback != null) {
            callback.onResult(null, null, 0, 0, null, false);
        }
    }

    private static void handleGalleryResult(Intent data) {
        if (data != null && data.getData() != null) {
            Uri selectedImageUri = data.getData();
            String path = getRealPathFromURI(selectedImageUri);
            if (path != null) {
                processImage(path);
            } else {
                // Try to get from URI directly
                processImageFromUri(selectedImageUri);
            }
        } else {
            if (callback != null) {
                callback.onResult(null, null, 0, 0, null, false);
            }
        }
    }

    private static void processImage(String path) {
        try {
            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inJustDecodeBounds = true;
            BitmapFactory.decodeFile(path, options);

            int width = options.outWidth;
            int height = options.outHeight;

            if (maxWidth > 0 && maxHeight > 0) {
                int sampleSize = Math.max(width / maxWidth, height / maxHeight);
                if (sampleSize < 1) sampleSize = 1;
                options.inSampleSize = sampleSize;
            }

            options.inJustDecodeBounds = false;
            Bitmap bitmap = BitmapFactory.decodeFile(path, options);

            if (bitmap != null) {
                ByteArrayOutputStream stream = new ByteArrayOutputStream();
                int quality = currentQuality == 0 ? 30 : (currentQuality == 1 ? 60 : (currentQuality == 2 ? 90 : 100));
                bitmap.compress(Bitmap.CompressFormat.JPEG, quality, stream);
                byte[] data = stream.toByteArray();
                bitmap.recycle();

                if (callback != null) {
                    callback.onResult(path, data, bitmap.getWidth(), bitmap.getHeight(), "image/jpeg", true);
                }
            } else {
                if (callback != null) {
                    callback.onResult(null, null, 0, 0, null, false);
                }
            }
        } catch (Exception e) {
            Log.e("ImagePicker", "Error processing image", e);
            if (callback != null) {
                callback.onResult(null, null, 0, 0, null, false);
            }
        }
    }

    private static void processImageFromUri(Uri uri) {
        try {
            ContentResolver resolver = currentActivity.getContentResolver();
            Bitmap bitmap = MediaStore.Images.Media.getBitmap(resolver, uri);

            if (bitmap != null) {
                ByteArrayOutputStream stream = new ByteArrayOutputStream();
                int quality = currentQuality == 0 ? 30 : (currentQuality == 1 ? 60 : (currentQuality == 2 ? 90 : 100));
                bitmap.compress(Bitmap.CompressFormat.JPEG, quality, stream);
                byte[] data = stream.toByteArray();
                bitmap.recycle();

                if (callback != null) {
                    callback.onResult(null, data, bitmap.getWidth(), bitmap.getHeight(), "image/jpeg", true);
                }
            } else {
                if (callback != null) {
                    callback.onResult(null, null, 0, 0, null, false);
                }
            }
        } catch (Exception e) {
            Log.e("ImagePicker", "Error processing image from URI", e);
            if (callback != null) {
                callback.onResult(null, null, 0, 0, null, false);
            }
        }
    }

    private static String getRealPathFromURI(Uri contentUri) {
        String[] projection = {MediaStore.Images.Media.DATA};
        Cursor cursor = currentActivity.getContentResolver().query(contentUri, projection, null, null, null);
        if (cursor == null) return null;
        int columnIndex = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA);
        cursor.moveToFirst();
        String path = cursor.getString(columnIndex);
        cursor.close();
        return path;
    }

    public static void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        if (requestCode == REQUEST_CAMERA_PERMISSION) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                launchCamera();
            } else {
                if (callback != null) {
                    callback.onResult(null, null, 0, 0, null, false);
                }
            }
        } else if (requestCode == REQUEST_STORAGE_PERMISSION) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                launchGallery();
            } else {
                if (callback != null) {
                    callback.onResult(null, null, 0, 0, null, false);
                }
            }
        }
    }
}
