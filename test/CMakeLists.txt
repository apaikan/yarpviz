cmake_minimum_required(VERSION 2.8)

project(test)

find_package(YARP)

include_directories(${YARP_INCLUDE_DIRS})

add_executable(test test.cpp)

target_link_libraries(test ${YARP_LIBRARIES})

install(TARGETS test
	RUNTIME DESTINATION 	${CMAKE_CURRENT_SOURCE_DIR}/../bin)


