#include <fstream>
#include "ReadImageProcess.h"
#include "ImageProcessor.h"
#include "Gif.h"

const ImageProcessInput ReadImageProcess::Process(const ImageProcessInput &input, picojson::object &result) {
    auto buffer = input.GetBuffer();

    cv::Mat image;

    if(flatten == Flatten::None) {
        image = cv::imdecode(*buffer, cv::IMREAD_COLOR);
    } else {
        image = cv::imdecode(*buffer, cv::IMREAD_UNCHANGED);

        if(image.depth() != CV_8U || image.channels() != 3){
            cv::Mat flattend;

            if(TryFlatten(image, flattend)) {
                image = flattend;
                result["flatten"] = picojson::value(ToString(flatten));
            } else {
                image = cv::imdecode(*buffer, cv::IMREAD_COLOR);
            }
        }
    }

    if(!image.empty()) {
        result["width"] = picojson::value((double)image.cols);
        result["height"] = picojson::value((double)image.rows);

        easyexif::EXIFInfo exif;

        if(TryReadExif(buffer, exif)) {
            if(autoOrient) {
                cv::Mat oriented;
                auto orientation = exif.Orientation;
                if(TryRotateOrientation(image, oriented, orientation)){
                    image = oriented;
                }
                result["orientation"] = picojson::value((double)orientation);
            }
        }
        return ImageProcessInput(image);
    }

    Gif gif;

    if(!Gif::TryReadFromBuffer(buffer, gif, flatten)){
        throw std::runtime_error("cant open file: " + to);
    }

    result["width"] = picojson::value((double)gif.GetWidth());
    result["height"] = picojson::value((double)gif.GetHeight());
    result["flatten"] = picojson::value(ToString(flatten));
    result["frames"] = picojson::value((double)gif.GetFrameCount());
    return ImageProcessInput(gif);
}

bool ReadImageProcess::TryFlatten(const cv::Mat &src, cv::Mat &dest) {
    if(src.depth() == CV_8U && src.channels() == 4) {
        dest = cv::Mat(src.size(), CV_8UC3);
        cv::Scalar backgroundPixel;
        cv::Scalar destPixel;

        switch(flatten){
            case Flatten::Black:
                backgroundPixel = cv::Scalar(0,0,0,1);
                break;
            case Flatten::White:
                backgroundPixel = cv::Scalar(1,1,1,1);
                break;
            default:
                return false;
        }

        for (int y = 0; y < src.rows; ++y) {
            unsigned  char * srcPtr = src.data + src.step * y;
            unsigned  char * destPtr = dest.data + dest.step * y;

            for(int x = 0; x < src.cols; ++x) {
                cv::Scalar srcPixel(srcPtr[0] / 255.0, srcPtr[1] / 255.0,srcPtr[2] / 255.0, srcPtr[3] / 255.0);
                cv::addWeighted(srcPixel, srcPixel[3], backgroundPixel, 1 - srcPixel[3], 0, destPixel);

                destPtr[0] = (unsigned char)(destPixel[0] * 255);
                destPtr[1] = (unsigned char)(destPixel[1] * 255);
                destPtr[2] = (unsigned char)(destPixel[2] * 255);

                destPtr+= dest.channels();
                srcPtr+= src.channels();
            }
        }
        return true;
    }
    return false;
}

bool ReadImageProcess::TryReadExif(const std::shared_ptr<std::vector<unsigned char>> &buffer, easyexif::EXIFInfo & exif) {
    int code = exif.parseFrom(buffer->data(),(int)buffer->size());
    if (code) {
        return false;
    }
    return true;
}

bool ReadImageProcess::TryRotateOrientation(const cv::Mat &src, cv::Mat & oriented, int orientation) {
    // http://www.impulseadventure.com/photo/exif-orientation.html
    cv::Mat transposed;

    switch(orientation){
        case 2:
            cv::flip(src, oriented, 1);
            break;
        case 3:
            cv::flip(src, oriented, -1);
            break;
        case 4:
            cv::flip(src, oriented, 0);
            break;
        case 5:
            cv::transpose(src, oriented);
            break;
        case 6:
            cv::transpose(src, transposed);
            cv::flip(transposed, oriented, 1);
            break;
        case 7:
            cv::transpose(src, transposed);
            cv::flip(transposed, oriented, -1);
            break;
        case 8:
            cv::transpose(src, transposed);
            cv::flip(transposed, oriented, 0);
            break;
    }
    if(oriented.empty()){
        return false;
    }

    return true;
}
