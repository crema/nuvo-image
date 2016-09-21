cmake_minimum_required(VERSION 3.0)

project(nuvo_image)


if(UNIX AND NOT APPLE)
    set (CMAKE_CXX_COMPILER g++-6)
    set (WITH_MOZJPEG ON)
endif()

set (CMAKE_CXX_STANDARD 11)
set (CMAKE_CXX_FLAGS '-o4')

include(ExternalProject)

# set(CMAKE_BUILD_TYPE Debug)

set(EXTERNAL_DIR ${CMAKE_SOURCE_DIR}/external)
set(EXTERNAL_SRC_DIR ${EXTERNAL_DIR}/src)
set(EXTERNAL_LIB_DIR ${EXTERNAL_DIR}/lib)

ExternalProject_Add(
        giflib
        URL ${EXTERNAL_DIR}/giflib-5.1.4.tar.bz2
        SOURCE_DIR ${EXTERNAL_SRC_DIR}/giflib-5.1.4
        CONFIGURE_COMMAND ${EXTERNAL_SRC_DIR}/giflib-5.1.4/configure --prefix=${EXTERNAL_LIB_DIR}/giflib-5.1.4
        BUILD_IN_SOURCE 1
)

if(WITH_MOZJPEG)

    set(MOZJPEG_CONFIGURE
            --enable-shared=no
            --without-turbojpeg
            --without-java
            --with-pic
            --prefix=${EXTERNAL_LIB_DIR}/mozjpeg-3.1)

    ExternalProject_Add(
            mozjpeg
            URL https://github.com/mozilla/mozjpeg/releases/download/v3.1/mozjpeg-3.1-release-source.tar.gz
            SOURCE_DIR ${EXTERNAL_SRC_DIR}/mozjpeg-3.1
            CONFIGURE_COMMAND ${EXTERNAL_SRC_DIR}/mozjpeg-3.1/configure ${MOZJPEG_CONFIGURE}
            BUILD_IN_SOURCE 1
    )
endif()

set(FFMPEG_CONFIGURE
        --disable-audiotoolbox
        --disable-videotoolbox
        --disable-vda
        --disable-iconv
        --disable-network
        --disable-zlib
        --disable-xlib
        --disable-lzma
        --disable-sdl
        --disable-bzlib
        --disable-doc
        --enable-nonfree
        --enable-pic
        --enable-gpl
        --enable-static
        --disable-shared
        --enable-avresample
        --enable-libvpx
        --enable-libx264)

set(FFMPEG_CONFIGURE ${FFMPEG_CONFIGURE}
        --disable-decoders)

set(FFMPEG_CONFIGURE ${FFMPEG_CONFIGURE}
        --disable-encoders
        --enable-encoder=libvpx_vp8
        --enable-encoder=libx264)

set(FFMPEG_CONFIGURE ${FFMPEG_CONFIGURE}
        --disable-parsers
        --enable-parser=h264
        --enable-parser=vp8)

set(FFMPEG_CONFIGURE ${FFMPEG_CONFIGURE}
        --disable-demuxers)

set(FFMPEG_CONFIGURE ${FFMPEG_CONFIGURE}
        --disable-muxers
        --enable-muxer=mp4
        --enable-muxer=h264
        --enable-muxer=webm)

set(FFMPEG_CONFIGURE ${FFMPEG_CONFIGURE}
        --disable-protocols
        --enable-protocol=file)

set(FFMPEG_CONFIGURE ${FFMPEG_CONFIGURE}
        --disable-filters)

set(FFMPEG_CONFIGURE ${FFMPEG_CONFIGURE}
        --disable-bsfs)

set(FFMPEG_CONFIGURE ${FFMPEG_CONFIGURE}
        --disable-indevs)

set(FFMPEG_CONFIGURE ${FFMPEG_CONFIGURE}
        --disable-outdevs)

set(FFMPEG_CONFIGURE ${FFMPEG_CONFIGURE}
        --prefix=${EXTERNAL_LIB_DIR}/ffmpeg-3.1.1)

ExternalProject_Add(
        ffmpeg
        URL http://ffmpeg.org/releases/ffmpeg-3.1.1.tar.bz2
        SOURCE_DIR ${EXTERNAL_SRC_DIR}/ffmpeg-3.1.1
        CONFIGURE_COMMAND ${EXTERNAL_SRC_DIR}/ffmpeg-3.1.1/configure ${FFMPEG_CONFIGURE}
        BUILD_IN_SOURCE 1
)

ExternalProject_Add(
        opencv
        URL https://github.com/Itseez/opencv/archive/3.1.0.zip
        SOURCE_DIR ${EXTERNAL_SRC_DIR}/opencv3.1.0
        PATCH_COMMAND cat ${EXTERNAL_DIR}/opencv_patch.cmake >> ${EXTERNAL_SRC_DIR}/opencv3.1.0/cmake/OpenCVFindLibsVideo.cmake
        CMAKE_ARGS -C${EXTERNAL_DIR}/opencv_config.cmake
        BUILD_IN_SOURCE 1
)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/build/bin)


include_directories(include
        ${OpenCV_INCLUDE_DIR}
        ${EXTERNAL_LIB_DIR}/giflib-5.1.4/include
        ${EXTERNAL_LIB_DIR}/opencv3.1.0/include)

set(SOURCE_FILES
        src/main.cpp
        src/exif.cpp
        src/Gif.cpp
        src/Enums.cpp
        src/ImageProcessor.cpp
        src/ImageProcess.cpp
        src/ReadImageProcess.cpp
        src/CropImageProcess.cpp
        src/ResizeImageProcess.cpp
        src/LossyImageProcess.cpp
        src/FrameImageProcess.cpp
        src/VideoImageProcess.cpp
        src/ClearMemoryProcess.cpp)

add_executable(nuvo_image ${SOURCE_FILES})

if(WITH_MOZJPEG)
    add_dependencies(opencv mozjpeg)
endif()

add_dependencies(opencv ffmpeg)
add_dependencies(nuvo_image giflib opencv)

set(GIF_LIBRARIES ${EXTERNAL_LIB_DIR}/giflib-5.1.4/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gif${CMAKE_STATIC_LIBRARY_SUFFIX})
set(OPENCV_CORE_LIBRARIES ${EXTERNAL_LIB_DIR}/opencv3.1.0/lib/${CMAKE_SHARED_LIBRARY_PREFIX}opencv_core${CMAKE_SHARED_LIBRARY_SUFFIX})
set(OPENCV_IMGPROC_LIBRARIES ${EXTERNAL_LIB_DIR}/opencv3.1.0/lib/${CMAKE_SHARED_LIBRARY_PREFIX}opencv_imgproc${CMAKE_SHARED_LIBRARY_SUFFIX})
set(OPENCV_IMGCODECS_LIBRARIES ${EXTERNAL_LIB_DIR}/opencv3.1.0/lib/${CMAKE_SHARED_LIBRARY_PREFIX}opencv_imgcodecs${CMAKE_SHARED_LIBRARY_SUFFIX})
set(OPENCV_VIDEOIO_LIBRARIES ${EXTERNAL_LIB_DIR}/opencv3.1.0/lib/${CMAKE_SHARED_LIBRARY_PREFIX}opencv_videoio${CMAKE_SHARED_LIBRARY_SUFFIX})

target_link_libraries(nuvo_image
        ${GIF_LIBRARIES}
        ${OPENCV_CORE_LIBRARIES}
        ${OPENCV_IMGPROC_LIBRARIES}
        ${OPENCV_IMGCODECS_LIBRARIES}
        ${OPENCV_VIDEOIO_LIBRARIES})

install (TARGETS nuvo_image DESTINATION bin)
