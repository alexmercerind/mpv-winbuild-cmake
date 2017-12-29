set(rev "R40")

if(${TARGET_CPU} MATCHES "x86_64")
    set(link "https://github.com/vapoursynth/vapoursynth/releases/download/${rev}/VapourSynth64-Portable-${rev}.7z")
    set(hash "93531bacf32a9ffed026819aabe52f09366fa4444c561624b7c38cf90fe67302")
else()
    set(link "https://github.com/vapoursynth/vapoursynth/releases/download/${rev}/VapourSynth32-Portable-${rev}.7z")
    set(hash "153998e065ed78238a027019995cf4a2b08c0cffe477e2ade2045347c0a51b20")
endif()

string(REPLACE "R" "" PC_VERSION ${rev})
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/vapoursynth.pc.in ${CMAKE_CURRENT_BINARY_DIR}/vapoursynth.pc @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/vapoursynth-script.pc.in ${CMAKE_CURRENT_BINARY_DIR}/vapoursynth-script.pc @ONLY)
set(GENERATE_DEF ${CMAKE_CURRENT_BINARY_DIR}/vapoursynth-prefix/src/generate_def.sh)
file(WRITE ${GENERATE_DEF}
"#!/bin/sh
gendef - $1.dll | sed -r -e 's|^_||' -e 's|@[1-9]+$||' > $1.def")

ExternalProject_Add(vapoursynth
    URL ${link}
    URL_HASH SHA256=${hash}
    UPDATE_COMMAND ""
    PATCH_COMMAND ""
    CONFIGURE_COMMAND ""
    BUILD_COMMAND ""
    INSTALL_COMMAND ""
    LOG_DOWNLOAD 1 LOG_UPDATE 1
)

ExternalProject_Add_Step(vapoursynth generate-def
    DEPENDEES install
    WORKING_DIRECTORY <SOURCE_DIR>
    COMMAND ${EXEC} ${GENERATE_DEF} VSScript
    COMMAND ${EXEC} ${GENERATE_DEF} VapourSynth
)

ExternalProject_Add_Step(vapoursynth generate-lib
    DEPENDEES generate-def
    WORKING_DIRECTORY <SOURCE_DIR>
    COMMAND ${EXEC} ${TARGET_ARCH}-dlltool -d VSScript.def -l libvsscript.a
    COMMAND ${EXEC} ${TARGET_ARCH}-dlltool -d VapourSynth.def -l libvapoursynth.a
)

ExternalProject_Add_Step(vapoursynth download-header
    DEPENDEES generate-lib
    WORKING_DIRECTORY <SOURCE_DIR>
    COMMAND curl -sOL https://github.com/vapoursynth/vapoursynth/raw/${rev}/include/VapourSynth.h
    COMMAND curl -sOL https://github.com/vapoursynth/vapoursynth/raw/${rev}/include/VSScript.h
    COMMAND curl -sOL https://github.com/vapoursynth/vapoursynth/raw/${rev}/include/VSHelper.h
)

ExternalProject_Add_Step(vapoursynth manual-install
    DEPENDEES download-header
    WORKING_DIRECTORY <SOURCE_DIR>
    # Copying header
    COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/VapourSynth.h ${MINGW_INSTALL_PREFIX}/include/vapoursynth/VapourSynth.h
    COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/VSScript.h ${MINGW_INSTALL_PREFIX}/include/vapoursynth/VSScript.h
    COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/VSHelper.h ${MINGW_INSTALL_PREFIX}/include/vapoursynth/VSHelper.h
    # Copying libs
    COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/libvsscript.a ${MINGW_INSTALL_PREFIX}/lib/libvsscript.a
    COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/libvapoursynth.a ${MINGW_INSTALL_PREFIX}/lib/libvapoursynth.a
    # Copying .pc files
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/vapoursynth.pc ${MINGW_INSTALL_PREFIX}/lib/pkgconfig/vapoursynth.pc
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/vapoursynth-script.pc ${MINGW_INSTALL_PREFIX}/lib/pkgconfig/vapoursynth-script.pc
    # Copying .dll files
    COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/VSScript.dll ${CMAKE_CURRENT_BINARY_DIR}/mpv-package/vsscript.dll
    COMMAND ${CMAKE_COMMAND} -E copy <SOURCE_DIR>/VapourSynth.dll ${CMAKE_CURRENT_BINARY_DIR}/mpv-package/vapoursynth.dll
)

extra_step(vapoursynth)
