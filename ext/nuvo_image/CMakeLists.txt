cmake_minimum_required(VERSION 3.0)

project(nuvo_image)

if (UNIX AND NOT APPLE)
        set(CMAKE_CXX_COMPILER g++-6)
endif ()

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_FLAGS '-o4')

include(ExternalProject)

# set(CMAKE_BUILD_TYPE Debug)

set(EXTERNAL_DIR ${CMAKE_SOURCE_DIR}/external)
set(EXTERNAL_SRC_DIR ${EXTERNAL_DIR}/src)
set(EXTERNAL_LIB_DIR ${EXTERNAL_DIR}/lib)

set(FFMPEG_CONFIGURE
        --disable-audiotoolbox
        --disable-bzlib
        --disable-doc
        --disable-iconv
        --disable-lzma
        --disable-network
        --disable-sdl
        --disable-vda
        --disable-videotoolbox
        --disable-xlib
        --disable-zlib
        --enable-avresample
        --enable-gpl
        --enable-libx264
        --enable-nonfree
        --enable-pic
)
set(FFMPEG_CONFIGURE ${FFMPEG_CONFIGURE}
        --disable-bsfs
        --disable-decoders
        --disable-demuxers
        --disable-encoders
        --disable-filters
        --disable-indevs
        --disable-muxers
        --disable-outdevs
        --disable-parsers
        --disable-programs
        --disable-protocols
        --enable-encoder=libx264
        --enable-muxer=h264
        --enable-muxer=mp4
        --enable-parser=h264
        --enable-protocol=file
)
set(FFMPEG_CONFIGURE ${FFMPEG_CONFIGURE}
        --prefix=${EXTERNAL_LIB_DIR}/ffmpeg-3.2.4
)
ExternalProject_Add(
        ffmpeg
        URL ${EXTERNAL_DIR}/ffmpeg-3.2.4.tar.bz2
        SOURCE_DIR ${EXTERNAL_SRC_DIR}/ffmpeg-3.2.4
        CONFIGURE_COMMAND ${EXTERNAL_SRC_DIR}/ffmpeg-3.2.4/configure ${FFMPEG_CONFIGURE}
        BUILD_IN_SOURCE 1
)

if (UNIX AND NOT APPLE)
        set(MOZJPEG_CONFIGURE
                --enable-shared=no
                --without-turbojpeg
                --with-pic
                --prefix=${EXTERNAL_LIB_DIR}/mozjpeg-3.1
        )
        ExternalProject_Add(
                mozjpeg
                URL ${EXTERNAL_DIR}/mozjpeg-3.1-release-source.tar.gz
                SOURCE_DIR ${EXTERNAL_SRC_DIR}/mozjpeg-3.1
                CONFIGURE_COMMAND ${EXTERNAL_SRC_DIR}/mozjpeg-3.1/configure ${MOZJPEG_CONFIGURE}
                BUILD_IN_SOURCE 1
        )
endif ()

ExternalProject_Add(
        opencv
        URL ${EXTERNAL_DIR}/opencv-3.2.0.zip
        SOURCE_DIR ${EXTERNAL_SRC_DIR}/opencv-3.2.0
        CMAKE_ARGS -C${EXTERNAL_DIR}/opencv_config.cmake
        BUILD_IN_SOURCE 1
)

set(GIFLIB_CONFIGURE
        have_xmlto=no
        --enable-shared=no
        --prefix=${EXTERNAL_LIB_DIR}/giflib-5.1.4
)
ExternalProject_Add(
        giflib
        GIT_REPOSITORY https://github.com/crema/giflib
        SOURCE_DIR ${EXTERNAL_SRC_DIR}/giflib-5.1.4
        CONFIGURE_COMMAND ${EXTERNAL_SRC_DIR}/giflib-5.1.4/configure ${GIFLIB_CONFIGURE}
        BUILD_IN_SOURCE 1
)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/build/bin)

include_directories(include
        ${OpenCV_INCLUDE_DIR}
        ${EXTERNAL_LIB_DIR}/giflib-5.1.4/include
        ${EXTERNAL_LIB_DIR}/opencv-3.2.0/include)

file(GLOB INCLUDE_FILES include/*.h)
file(GLOB SOURCE_FILES src/*.cpp)

add_executable(nuvo_image ${INCLUDE_FILES} ${SOURCE_FILES})

if (UNIX AND NOT APPLE)
        add_dependencies(opencv mozjpeg)
endif ()

add_dependencies(opencv ffmpeg)
add_dependencies(nuvo_image giflib opencv)

set(GIF_LIBRARIES ${EXTERNAL_LIB_DIR}/giflib-5.1.4/lib/${CMAKE_STATIC_LIBRARY_PREFIX}gif${CMAKE_STATIC_LIBRARY_SUFFIX})
set(OPENCV_CORE_LIBRARIES ${EXTERNAL_LIB_DIR}/opencv-3.2.0/lib/${CMAKE_SHARED_LIBRARY_PREFIX}opencv_core${CMAKE_SHARED_LIBRARY_SUFFIX})
set(OPENCV_IMGPROC_LIBRARIES ${EXTERNAL_LIB_DIR}/opencv-3.2.0/lib/${CMAKE_SHARED_LIBRARY_PREFIX}opencv_imgproc${CMAKE_SHARED_LIBRARY_SUFFIX})
set(OPENCV_IMGCODECS_LIBRARIES ${EXTERNAL_LIB_DIR}/opencv-3.2.0/lib/${CMAKE_SHARED_LIBRARY_PREFIX}opencv_imgcodecs${CMAKE_SHARED_LIBRARY_SUFFIX})
set(OPENCV_VIDEOIO_LIBRARIES ${EXTERNAL_LIB_DIR}/opencv-3.2.0/lib/${CMAKE_SHARED_LIBRARY_PREFIX}opencv_videoio${CMAKE_SHARED_LIBRARY_SUFFIX})

target_link_libraries(nuvo_image
        ${GIF_LIBRARIES}
        ${OPENCV_CORE_LIBRARIES}
        ${OPENCV_IMGPROC_LIBRARIES}
        ${OPENCV_IMGCODECS_LIBRARIES}
        ${OPENCV_VIDEOIO_LIBRARIES})

install(TARGETS nuvo_image DESTINATION bin)
