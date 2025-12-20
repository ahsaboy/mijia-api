#!/data/data/com.termux/files/usr/bin/bash
# Nuitka 编译脚本 - 生成 Android 原生可执行文件

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo "=== mijiaAPI Nuitka 编译 ==="
echo "项目目录: $PROJECT_DIR"
echo "Python: $(python3 --version)"
echo "Nuitka: $(python3 -m nuitka --version | head -1)"
echo ""

# 编译选项说明:
# --standalone: 创建独立目录，包含所有依赖
# --onefile: 打包成单个可执行文件（需要更长编译时间）
# --follow-imports: 跟踪并包含所有导入
# --include-package: 包含整个包
# --enable-plugin=anti-bloat: 减少体积
# --assume-yes-for-downloads: 自动下载需要的依赖

BUILD_MODE="${1:-standalone}"

if [ "$BUILD_MODE" = "onefile" ]; then
    echo "编译模式: 单文件 (onefile)"
    ONEFILE_FLAG="--onefile"
    OUTPUT_DESC="可执行文件将生成在 dist/mijiaAPI"
else
    echo "编译模式: 独立目录 (standalone)"
    ONEFILE_FLAG="--standalone"
    OUTPUT_DESC="可执行文件将生成在 mijiaAPI.dist/ 目录"
fi

echo ""
echo "开始编译..."
echo ""

python3 -m nuitka \
    $ONEFILE_FLAG \
    --follow-imports \
    --include-package=mijiaAPI \
    --include-package=PIL \
    --include-package=Crypto \
    --include-package=qrcode \
    --include-package=requests \
    --include-package=tzlocal \
    --include-package=urllib3 \
    --include-package=charset_normalizer \
    --include-package=certifi \
    --include-package=idna \
    --enable-plugin=anti-bloat \
    --remove-output \
    --assume-yes-for-downloads \
    --output-filename=mijiaAPI \
    --output-dir=dist \
    main.py

echo ""
echo "=== 编译完成 ==="
echo "$OUTPUT_DESC"

if [ "$BUILD_MODE" = "onefile" ]; then
    if [ -f "dist/mijiaAPI" ]; then
        ls -lh dist/mijiaAPI
        echo ""
        echo "测试运行: ./dist/mijiaAPI --version"
    fi
else
    if [ -d "dist/main.dist" ]; then
        mv dist/main.dist dist/mijiaAPI.dist 2>/dev/null || true
    fi
    if [ -d "dist/mijiaAPI.dist" ]; then
        # 复制 libpython 到 dist 目录
        LIBPYTHON="$PREFIX/lib/libpython3.12.so.1.0"
        if [ -f "$LIBPYTHON" ]; then
            cp "$LIBPYTHON" dist/mijiaAPI.dist/
            ln -sf libpython3.12.so.1.0 dist/mijiaAPI.dist/libpython3.12.so
            echo "已复制 libpython3.12.so.1.0"
        fi

        # 创建启动脚本
        cat > dist/mijiaAPI.dist/run_mijiaAPI.sh << 'RUNSCRIPT'
#!/data/data/com.termux/files/usr/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export LD_LIBRARY_PATH="$SCRIPT_DIR:$LD_LIBRARY_PATH"
exec "$SCRIPT_DIR/mijiaAPI" "$@"
RUNSCRIPT
        chmod +x dist/mijiaAPI.dist/run_mijiaAPI.sh

        echo ""
        ls -lh dist/mijiaAPI.dist/ | head -20
        echo ""
        echo "测试运行: ./dist/mijiaAPI.dist/run_mijiaAPI.sh --version"
        echo "或直接: LD_LIBRARY_PATH=dist/mijiaAPI.dist ./dist/mijiaAPI.dist/mijiaAPI --version"
    fi
fi
