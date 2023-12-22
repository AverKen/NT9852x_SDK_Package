#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import pyfdt
import json
import argparse
# some oaalnx has no colorama
#import colorama
from pyfdt import FdtBlobParse


def dbg_err(msg):
    #print(colorama.Fore.RED+colorama.Style.BRIGHT+msg+colorama.Style.RESET_ALL, file=sys.stderr)
    print(msg, file=sys.stderr)


def dbg_wrn(msg):
    #print(colorama.Fore.YELLOW+colorama.Style.BRIGHT+msg+colorama.Style.RESET_ALL, file=sys.stderr)
    print(msg, file=sys.stderr)


def parse_nvt_info(fdt):
    nvt_info = dict()
    fdt_nvt_info = fdt.to_fdt().resolve_path(r'/nvt_info')
    iter = fdt_nvt_info.walk()
    for item in iter:
        if isinstance(item[1], pyfdt.FdtPropertyStrings):
            nvt_info[item[1].name] = item[1].strings[0]
        else:
            nvt_info[item[1].name] = ""
    return nvt_info


def parse_flash_partition(fdt, flash_path):
    partitions = []
    fdt_partitions = fdt.to_fdt().resolve_path(flash_path)
    if fdt_partitions is None:
        return partitions
    iter = fdt_partitions.walk()
    for item in iter:
        if not isinstance(item[1], pyfdt.FdtNode):
            continue
        if "partition_" not in item[1].name:
            continue
        partition = dict()
        partition["name"] = item[1].name
        iter2 = item[1].walk()
        for item2 in iter2:
            if item2[1].name == "label":
                partition["label"] = item2[1].strings[0]
            elif item2[1].name == "reg":
                partition["ofs"] = (item2[1].words[0] <<
                                    64) | (item2[1].words[1])
                partition["size"] = (item2[1].words[2] <<
                                     64) | (item2[1].words[3])
        partitions.append(partition)
    return partitions


def parse_nvt_memory_cfg(fdt):
    nvt_memory_cfgs = []
    fdt_nvt_memory_cfg = fdt.to_fdt().resolve_path(r"/nvt_memory_cfg")
    iter = fdt_nvt_memory_cfg.walk()
    for item in iter:
        if not isinstance(item[1], pyfdt.FdtNode):
            continue
        nvt_memory_cfg = dict()
        nvt_memory_cfg["name"] = item[1].name
        iter2 = item[1].walk()
        for item2 in iter2:
            if item2[1].name == "reg":
                nvt_memory_cfg["ofs"] = item2[1].words[0]
                nvt_memory_cfg["size"] = item2[1].words[1]
        nvt_memory_cfgs.append(nvt_memory_cfg)
    return nvt_memory_cfgs


def parse_linux_memory(fdt):
    linux_memories = []
    fdt_linux_memory = fdt.to_fdt().resolve_path(r"/memory/reg")
    for idx in range(int(len(fdt_linux_memory.words)/2)):
        linux_memory = dict()
        linux_memory["ofs"] = fdt_linux_memory.words[idx*2]
        linux_memory["size"] = fdt_linux_memory.words[idx*2+1]
        linux_memories.append(linux_memory)
    return linux_memories


def parse_reserved_memory(fdt):
    reserved_memories = []
    fdt_reserved_memory = fdt.to_fdt().resolve_path(r"/reserved-memory")
    if fdt_reserved_memory is None:
        return reserved_memories
    iter = fdt_reserved_memory.walk()
    for item in iter:
        if not isinstance(item[1], pyfdt.FdtNode):
            continue
        reserved_memory = dict()
        reserved_memory["name"] = item[1].name
        reserved_memory["ofs"] = item[1][item[1].index("reg")].words[0]
        reserved_memory["size"] = item[1][item[1].index("reg")].words[1]
        reserved_memories.append(reserved_memory)
    return reserved_memories


def parse_hdal_memory(fdt):
    hdal_memory = dict()
    fdt_hdal_memory = fdt.to_fdt().resolve_path(r"/hdal-memory/media/reg")
    hdal_memory["ofs"] = fdt_hdal_memory.words[0]
    hdal_memory["size"] = fdt_hdal_memory.words[1]
    return hdal_memory


def parse_nvtpack(fdt, flash_path):
    nvtpack_items = []
    fdt_nvtpack = fdt.to_fdt().resolve_path(flash_path + r"/nvtpack/index")
    if fdt_nvtpack is None:
        return nvtpack_items
    iter = fdt_nvtpack.walk()
    for item in iter:
        if not isinstance(item[1], pyfdt.FdtNode):
            continue
        if "id" not in item[1].name:
            continue
        nvtpack_item = dict()
        nvtpack_item["id"] = item[1].name
        iter2 = item[1].walk()
        for item2 in iter2:
            if item2[1].name == "partition_name":
                nvtpack_item["partition_name"] = item2[1].strings[0]
        nvtpack_items.append(nvtpack_item)
    return nvtpack_items


def parse_top(fdt):
    top = dict()
    fdt_top = fdt.to_fdt().resolve_path(r"/top@f0010000")
    if fdt_top is None:
        return top
    iter = fdt_top.walk()
    for item in iter:
        if not isinstance(item[1], pyfdt.FdtNode):
            continue
        top[item[1].name] = item[1][0].words[0]
    return top


def check_nvt_info_embmem(nvt_info):
    if nvt_info["EMBMEM"] == "EMBMEM_NONE":
        return 0  # no embmem
    if nvt_info["EMBMEM"] == "EMBMEM_NAND":
        dbg_err("EMBMEM_NAND has deprecated.".format(
            nvt_info["EMBMEM"], nvt_info["EMBMEM_BLK_SIZE"]))
        return -1
    if nvt_info["EMBMEM"] == "EMBMEM_SPI_NOR" and nvt_info["EMBMEM_BLK_SIZE"] != "0x10000":
        dbg_err("EMBMEM({}) and EMBMEM_BLK_SIZE({}) are not matched".format(
            nvt_info["EMBMEM"], nvt_info["EMBMEM_BLK_SIZE"]))
        return -1
    if nvt_info["EMBMEM"] == "EMBMEM_SPI_NAND" and nvt_info["EMBMEM_BLK_SIZE"] != "0x20000" and nvt_info["EMBMEM_BLK_SIZE"] != "0x40000":
        dbg_err("EMBMEM({}) and EMBMEM_BLK_SIZE({}) are not matched".format(
            nvt_info["EMBMEM"], nvt_info["EMBMEM_BLK_SIZE"]))
        return -1
    if nvt_info["EMBMEM"] == "EMBMEM_EMMC" and nvt_info["EMBMEM_BLK_SIZE"] != "0x200":
        dbg_err("EMBMEM({}) and EMBMEM_BLK_SIZE({}) are not matched".format(
            nvt_info["EMBMEM"], nvt_info["EMBMEM_BLK_SIZE"]))
        return -1
    # check NVT_ROOTFS_TYPE
    if nvt_info["NVT_ROOTFS_TYPE"] == "NVT_ROOTFS_TYPE_RAMDISK":
        pass
    elif nvt_info["NVT_ROOTFS_TYPE"] == "NVT_ROOTFS_TYPE_SQUASH":
        pass
    elif nvt_info["EMBMEM"] == "EMBMEM_SPI_NOR" and "NVT_ROOTFS_TYPE_NOR" not in nvt_info["NVT_ROOTFS_TYPE"]:
        dbg_err("NVT_ROOTFS_TYPE must be NVT_ROOTFS_TYPE_RAMDISK or NVT_ROOTFS_TYPE_NOR* or NVT_ROOTFS_TYPE_SQUASH")
        return -1
    elif nvt_info["EMBMEM"] == "EMBMEM_SPI_NAND" and "NVT_ROOTFS_TYPE_NAND" not in nvt_info["NVT_ROOTFS_TYPE"]:
        dbg_err("NVT_ROOTFS_TYPE must be NVT_ROOTFS_TYPE_RAMDISK or NVT_ROOTFS_TYPE_NAND* or NVT_ROOTFS_TYPE_SQUASH")
        return -1
    elif nvt_info["EMBMEM"] == "EMBMEM_EMMC" and "NVT_ROOTFS_TYPE_EXT4" not in nvt_info["NVT_ROOTFS_TYPE"]:
        dbg_err("NVT_ROOTFS_TYPE must be NVT_ROOTFS_TYPE_RAMDISK or NVT_ROOTFS_TYPE_EXT4* or NVT_ROOTFS_TYPE_SQUASH")
        return -1
    return 0


def check_flash_partition(nvt_info, partitions):
    if nvt_info["EMBMEM"] == "EMBMEM_NONE":
        return 0  # no flash

    # check partition flash type matched with EMBMEM
    if len(partitions[nvt_info["EMBMEM"]]) == 0:
        dbg_err(
            "storage-partition type is not matched to {} ".format(nvt_info["EMBMEM"]))
        return -1
    # check partition size block
    blk_size = int(nvt_info["EMBMEM_BLK_SIZE"], 0)
    partition = partitions[nvt_info["EMBMEM"]]

    if len(partition) < 3:
        dbg_err("flash partition counts are less than 3. it doesn't make scene")
        return -1
    # check first must be loader or mbr and their size follow our spec
    if nvt_info["EMBMEM"] == "EMBMEM_EMMC":
        if partition[0]["name"] != "partition_mbr":
            dbg_err("first flash partition must be partition_mbr")
            return -1
        if partition[1]["name"] != "partition_fdt":
            dbg_err("2nd flash partition must be partition_fdt")
            return -1
        if partition[1]["ofs"] != 0x40000:
            dbg_err("2nd flash partition offset must be 0x40000 for EMMC")
            return -1
    else:
        if partition[0]["name"] != "partition_loader":
            dbg_err("first flash partition must be partition_loader")
            return -1
        if partition[1]["name"] != "partition_fdt":
            dbg_err("2nd flash partition must be partition_fdt")
            return -1
        if nvt_info["EMBMEM"] == "EMBMEM_SPI_NAND":
            if partition[1]["ofs"] != blk_size*2:
                dbg_err("2nd flash partition offset must be 0x{:X} for EMBMEM_SPI_NAND".format(
                    blk_size*2))
                return -1
        else:
            if partition[1]["ofs"] != blk_size:
                dbg_err(
                    "2nd flash partition offset must be 0x{:X} for EMBMEM_SPI_NOR".format(blk_size))
                return -1
    # check if partition_fdt.restore existing
    if partition[2]["name"] != "partition_fdt.restore":
        dbg_err("3nd flash partition suggest partition_fdt.restore")
    for item in partition:
        if item["size"] % blk_size != 0:
            dbg_err("flash partition {} is not {} bytes aligned.".format(
                item["label"], blk_size))
            return -1
    # check partition if in order and overlapped
    for idx in range(len(partition)):
        if idx == 0:
            continue
        if partition[idx]["ofs"] < partition[idx-1]["ofs"]+partition[idx-1]["size"] and partition[idx]["label"] != "all":
            dbg_err("partition {}@0x{:X}, 0x{:X} overlapped with {}@0x{:X}, 0x{:X}".format(
                partition[idx]["label"],
                partition[idx]["ofs"],
                partition[idx]["size"],
                partition[idx-1]["label"],
                partition[idx-1]["ofs"],
                partition[idx-1]["size"]))
            return -1
    return 0


def check_nvtpack(nvt_info, partitions, nvtpack_items):
    if nvt_info["EMBMEM"] == "EMBMEM_NONE":
        return 0  # no flash
    # check partition flash type matched with EMBMEM
    if len(nvtpack_items[nvt_info["EMBMEM"]]) == 0:
        dbg_err(
            "nvtpack-partition type is not matched to {} ".format(nvt_info["EMBMEM"]))
        return -1
    # check if id's partition_name is matched to storage partition
    partition = partitions[nvt_info["EMBMEM"]]
    nvtpack_item = nvtpack_items[nvt_info["EMBMEM"]]
    n_item = len(partition) if len(partition) < len(
        nvtpack_item) else len(nvtpack_item)
    for idx in range(n_item):
        nvtpack_partition_name = "partition_" + \
            nvtpack_item[idx]["partition_name"]
        if nvtpack_partition_name != partition[idx]["name"]:
            dbg_err("nvtpack index.{} partition name '{}' but '{}' is excepted.".format(
                idx,
                nvtpack_item[idx]["partition_name"],
                partition[idx]["name"].replace("partition_", "")))
            return -1
    return 0


def check_memory(nvt_memory_cfgs, linux_memories, reserved_memories, hdal_memory):
    fdt = None
    rtos = None
    bridge = None
    linuxtmp = None
    uboot = None
    # nvt_memory_cfgs first must be dram size
    if nvt_memory_cfgs[0]["name"] != "dram":
        dbg_err("nvt_memory_cfg first item must be 'dram' but rather '{}'".format(
            nvt_memory_cfgs[0]["name"]))
        return -1
    dram_size = nvt_memory_cfgs[0]["size"]
    # check each element if is over range
    for nvt_memory_cfg in nvt_memory_cfgs:
        if nvt_memory_cfg["ofs"]+nvt_memory_cfg["size"] > dram_size:
            dbg_err("nvt_memory_cfg's '{}' is out of dram size".format(
                nvt_memory_cfg["name"]))
            return -1
        # keep fdt, rtos, bridge info for checking fastboot sanity later
        if nvt_memory_cfg["name"] == "fdt":
            fdt = nvt_memory_cfg
        elif nvt_memory_cfg["name"] == "rtos":
            rtos = nvt_memory_cfg
        elif nvt_memory_cfg["name"] == "bridge":
            bridge = nvt_memory_cfg
        elif nvt_memory_cfg["name"] == "linuxtmp":
            linuxtmp = nvt_memory_cfg
        elif nvt_memory_cfg["name"] == "uboot":
            uboot = nvt_memory_cfg
    # check each element if in order and overlapped (disable it, becase rtos DEMO_EVB, rtos can overlap loader)
    """
    for idx in range(len(nvt_memory_cfgs)):
        if idx == 0:
            continue
        if nvt_memory_cfgs[idx]["ofs"] < nvt_memory_cfgs[idx-1]["ofs"]+nvt_memory_cfgs[idx-1]["size"] and nvt_memory_cfgs[idx-1]["name"] != "dram":
            dbg_err("nvt_memory_cfg {}@0x{:X}, 0x{:X} overlapped with {}@0x{:X}, 0x{:X}".format(
                nvt_memory_cfgs[idx]["name"],
                nvt_memory_cfgs[idx]["ofs"],
                nvt_memory_cfgs[idx]["size"],
                nvt_memory_cfgs[idx-1]["name"],
                nvt_memory_cfgs[idx-1]["ofs"],
                nvt_memory_cfgs[idx-1]["size"]))
            return -1
    """
    # check if linux memory is over range
    for linux_memory in linux_memories:
        # linux_memory["ofs"] < dram_size for skipping dram2
        if linux_memory["ofs"]+linux_memory["size"] > dram_size and linux_memory["ofs"] < dram_size:
            dbg_err("linux memory is out of dram size")
            return -1
    # check if hdal memory is over range
    # hdal_memory["ofs"] < dram_size for skipping dram2
    if hdal_memory["ofs"]+hdal_memory["size"] > dram_size and hdal_memory["ofs"] < dram_size:
        dbg_err("hdal memory is out of dram size")
        return -1

    # uboot memory cannot be overlapped with linux system memory region
    for linux_memory in linux_memories:
        if uboot["ofs"] > linux_memory["ofs"] and uboot["ofs"] < linux_memory["ofs"]+linux_memory["size"]:
            dbg_err(
                "uboot memory cannot be overlapped with linux system memory region")
            return -1
        if uboot["ofs"] < linux_memory["ofs"] and uboot["ofs"]+uboot["size"] > linux_memory["ofs"]:
            dbg_err(
                "uboot memory cannot be overlapped with linux system memory region")
            return -1

    # check reserved_memories must be in range of linux-memory and 4MB alignment
    for reserved_memory in reserved_memories:
        if (reserved_memory["size"] % 0x400000) != 0:
            dbg_err("{} size must be 4MB alignment".format(
                reserved_memory["name"]))
            return -1
        valid = 1
        for linux_memory in linux_memories:
            valid = 1
            if reserved_memory["ofs"] < linux_memory["ofs"]:
                valid = 0
                continue
            if reserved_memory["ofs"]+reserved_memory["size"] > linux_memory["ofs"]+linux_memory["size"]:
                valid = 0
                continue
            if valid:
                break
        if not valid:
            dbg_err(
                "{} is out of linux-memory".format(reserved_memory["name"]))
            return -1
    # check if hdal memory overlap with linux-memory
    for linux_memory in linux_memories:
        if hdal_memory["ofs"] > linux_memory["ofs"] and hdal_memory["ofs"] < linux_memory["ofs"]+linux_memory["size"]:
            dbg_err(
                "hdal_memory memory cannot be overlapped with linux system memory region")
            return -1
        if hdal_memory["ofs"] < linux_memory["ofs"] and hdal_memory["ofs"]+hdal_memory["size"] > linux_memory["ofs"]:
            dbg_err(
                "uboot memory cannot be overlapped with linux system memory region")
            return -1
    # if bridge exist, check fastboot requirement
    if bridge is not None:
        # check1: fdt, rtos and bridge memory region must be contiguous.
        if fdt["ofs"] + fdt["size"] != rtos["ofs"]:
            dbg_err("fdt, rtos and bridge memory region must be contiguous.")
            return -1
        if rtos["ofs"] + rtos["size"] != bridge["ofs"]:
            dbg_err("fdt, rtos and bridge memory region must be contiguous.")
            return -1
        hotplug_mem = dict()
        hotplug_mem["ofs"] = fdt["ofs"]
        hotplug_mem["size"] = fdt["size"] + rtos["size"] + bridge["size"]
        # check2: fdt, rtos and bridge memory region cannot overlap with hdal and linux memory
        for linux_memory in linux_memories:
            if hotplug_mem["ofs"] > linux_memory["ofs"] and hotplug_mem["ofs"] < linux_memory["ofs"]+linux_memory["size"]:
                dbg_err(
                    "fdt, rtos and bridge memory region cannot overlap with hdal and linux memory")
                return -1
            if hotplug_mem["ofs"] < linux_memory["ofs"] and hotplug_mem["ofs"]+hotplug_mem["size"] > linux_memory["ofs"]:
                dbg_err(
                    "fdt, rtos and bridge memory region cannot overlap with hdal and linux memory")
                return -1
        # check3: fdt, rtos and bridge memory region cannot overlap with linuxtmp
        if hotplug_mem["ofs"] > linuxtmp["ofs"] and hotplug_mem["ofs"] < linuxtmp["ofs"]+linuxtmp["size"]:
            dbg_err("fdt, rtos and bridge memory region cannot overlap with linuxtmp")
            return -1
        if hotplug_mem["ofs"] < linuxtmp["ofs"] and hotplug_mem["ofs"]+hotplug_mem["size"] > linuxtmp["ofs"]:
            dbg_err("fdt, rtos and bridge memory region cannot overlap with linuxtmp")
            return -1
        # check4: fdt, rtos and bridge memory have to start at 8MB alignment, and the size also needs 8MB alignment
        if (hotplug_mem["ofs"] % 0x800000) != 0:
            dbg_err(
                "fdt, rtos and bridge memory have to start at 8MB alignment, and the size also needs 8MB alignment")
            return -1
        if (hotplug_mem["size"] % 0x800000) != 0:
            dbg_err(
                "fdt, rtos and bridge memory have to start at 8MB alignment, and the size also needs 8MB alignment")
            return -1
    return 0


def check_top(top, nvt_info):
    if nvt_info["EMBMEM"] == "EMBMEM_SPI_NAND" and (top["nand"] & 0xC) == 0xC:
        dbg_err(
            "top/nand is incorrect: 0x{:X} for EMBMEM=EMBMEM_SPI_NAND".format(top["nand"]))
        return -1
    if nvt_info["EMBMEM"] == "EMBMEM_SPI_NOR" and (top["nand"] & 0xC) == 0xC:
        dbg_err(
            "top/nand is incorrect: 0x{:X} for EMBMEM=EMBMEM_SPI_NOR".format(top["nand"]))
        return -1
    if nvt_info["EMBMEM"] == "EMBMEM_EMMC" and (top["sdio3"] & 0x3) == 0x0:
        dbg_err(
            "top/sdio3 is incorrect: 0x{:X} for EMBMEM=EMBMEM_EMMC".format(top["sdio3"]))
        return -1
    return 0


def parse_args(argv):
    parser = argparse.ArgumentParser(description='fdt checker')
    parser.add_argument('-f', '--file', metavar='.dtb/.bin', required=True,
                        dest='file', action='store',
                        help='fdt binary file')
    args = parser.parse_args()
    return args


def main(argv):
    if 0:
        argv.append(r"-f")
        # argv.append(r"d:\tmp\nvt-na51055-evb.bin")
        argv.append(
            r"Z:\firmware\na51055_dual_sdk\na51055_linux_sdk\output\nvt-na51055-evb.bin")

    args = parse_args(argv)

    if not os.path.isfile(args.file):
        print("cannot find {}".format(args.file), file=sys.stderr)
        return -1

    print("verify {}".format(args.file))

    with open(args.file, 'rb') as infile:
        fdt = FdtBlobParse(infile)

    nvt_info = parse_nvt_info(fdt)
    partitions = dict()
    partitions["EMBMEM_SPI_NAND"] = parse_flash_partition(
        fdt, r"/nand@f0400000")
    partitions["EMBMEM_SPI_NOR"] = parse_flash_partition(fdt, r"/nor@f0400000")
    partitions["EMBMEM_EMMC"] = parse_flash_partition(fdt, r"/mmc@f0510000")
    nvt_memory_cfgs = parse_nvt_memory_cfg(fdt)
    linux_memories = parse_linux_memory(fdt)
    reserved_memories = parse_reserved_memory(fdt)
    hdal_memory = parse_hdal_memory(fdt)
    nvtpack_items = dict()
    nvtpack_items["EMBMEM_SPI_NAND"] = parse_nvtpack(fdt, r"/nand@f0400000")
    nvtpack_items["EMBMEM_SPI_NOR"] = parse_nvtpack(fdt, r"/nor@f0400000")
    nvtpack_items["EMBMEM_EMMC"] = parse_nvtpack(fdt, r"/mmc@f0510000")
    top = parse_top(fdt)

    if check_nvt_info_embmem(nvt_info) != 0:
        return -1
    if check_flash_partition(nvt_info, partitions) != 0:
        return -1
    if check_nvtpack(nvt_info, partitions, nvtpack_items) != 0:
        return -1
    if check_memory(nvt_memory_cfgs, linux_memories, reserved_memories, hdal_memory) != 0:
        return -1
    if check_top(top, nvt_info) != 0:
        return -1
    return 0


if __name__ == '__main__':
    try:
        # colorama.init()
        er = main(sys.argv)
    except Exception as exp:
        er = -1
        print(exp, file=sys.stderr)
        raise exp
    sys.exit(er)
