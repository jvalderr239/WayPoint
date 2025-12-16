# 🛰️ WayPoint: A Deep Dive into Robust 3D Human Perception

**Description:**

> WayPoint is a PyTorch-based 3D object detection framework designed to solve the *hard problem* of pedestrian and cyclist detection in massive-scale LiDAR environments. We sift through the complexity of the Waymo Open Dataset (WOD) by focusing on the Voxel-based pipeline for maximum real-time robustness.

## 1\. 💡 Why Am I Doing This?

We can assume 2D perception is mostly "solved" for classification. But truly **robust 3D perception**—especially for fragile objects like humans who are often occluded, far away, or moving fast—is still the frontier.

The Waymo Open Dataset is the gold standard. Its complexity (multiple LiDARs, huge fields of view, diverse urban/suburban scenes) exposes the limitations of toy models. **WayPoint** is our attempt to build a simple, clean architecture that:

1.  **Avoids the PointNet Tax:** Directly processing $100,000+$ raw points is slow and memory-intensive. We use voxelization for a grid-based approach.
2.  **Handles Scale Explosion:** The Waymo range is enormous. Our configuration handles the resultant $\sim 1500 \times 1500$ Bird-Eye-View (BEV) grid efficiently using sparse convolutions.
3.  **Prioritizes Vulnerable Users:** We are hyper-focused on $\text{TYPE}\_\text{PEDESTRIAN}$ and $\text{TYPE}\_\text{CYCLIST}$—the classes where failure is most costly in this dataset.

This exploration project really dives into the limitations of 3D perception.

## 2\. 🧱 The Architecture: From Point Cloud to Prediction

Our architecture is a classic VoxelNet-style pipeline, which we believe offers the best trade-off between performance and accuracy for production systems.

### A. The Data Ingester: `WaymoVoxelizer`

This isn't just a pre-processor; it's a feature extractor.

  * **Input:** Raw $\text{N} \times 4$ LiDAR points (x, y, z, reflectance).
  * **The Voxel Tax:** We map the massive Waymo range of $\pm 75.2m$ (X, Y) and $\pm 3.0m$ (Z) into voxels of size $\mathbf{0.1m \times 0.1m \times 0.15m}$. This quantization is a must for the grid structure.
  * **VFE Layer:** The **Voxel Feature Encoder** is where the magic takes shape. It takes the few points within each voxel ($T \le 5$) and uses a set of shared $\text{MLP}$s and $\text{Max}$ Pooling to generate a fixed-length feature vector. This is our first feature representation, invariant to the point order inside the voxel.

### B. The Engine: `BEVFeatureGenerator`

The output of the VFE is a highly **sparse** 3D tensor ($\approx 1.5$ million possible grid locations, but only $\approx 150,000$ non-empty voxels). We cannot use dense 3D $\text{CNN}$s; they would crush the $\text{GPU}$ memory.

  * **Sparse Convs:** We leverage the power of **sparse convolutions** (via `spconv`). These kernels only compute over the non-zero feature locations, vastly accelerating the 3D feature extraction.
  * **3D $\to$ 2D Collapse:** The 3D feature volume is aggressively reduced and finally collapsed into a 2D **Bird-Eye-View (BEV) Feature Map** by max-pooling along the height (Z) dimension. This $W \times H$ BEV tensor is the canonical representation for the rest of the pipeline.

### C. The Decision Maker: `BEVRPNHead`

This is our 2D head operating on the BEV grid.

  * **Input:** The high-resolution BEV feature map.
  * **RPN:** A standard 2D $\text{CNN}$ (our $\text{RPN}$) runs over this feature map to simultaneously predict:
    1.  **Classification:** Is there a pedestrian/cyclist here? (2 channels per anchor)
    2.  **Regression:** The 7-DOF bounding box parameters $(\Delta x, \Delta y, \Delta z, \Delta \text{dim}_x, \Delta \text{dim}_y, \Delta \text{dim}_z, \Delta \text{heading})$ relative to our predefined anchors.

## 3\. 🛠️ Getting Started: Running WayPoint

```bash
# 1. Clone the project
git clone https://github.com/YourUsername/WayPoint.git
cd WayPoint

# 2. Environment Setup
# We are deep learning engineers; we use an environment manager.
conda create -n waypoint python=3.10
conda activate waypoint
pip install -r requirements.txt
# NOTE: The 'spconv' dependency is often complex. Please follow the official
# documentation for building 'spconv' based on your CUDA version.

# 3. Data Prep: The Waymo Conversion Tax
# This script converts the official Waymo data format (.tfrecord) into
# manageable .bin files for PyTorch loading.
python scripts/data_converter.py --dataset waymo --input_path /path/to/waymo/raw

# 4. Training (Start Simple)
# Use the small, well-configured pedestrian-only model.
python scripts/train.py --cfg_file config/waymo_ped_voxel.yaml --gpus 1

# 5. Evaluation
python scripts/evaluate.py --model /path/to/best_checkpoint.pth
```

## 4\. 📈 Contributions and Next Steps

We've started with the Voxel-based baseline. The next steps for expert-level robust perception include:

1.  **Augmentation Deep Dive:** Implementing more sophisticated data augmentation specific to human detection (e.g., cut-and-paste augmentation for heavy occlusion).
2.  **Point-Feature Fusion:** Introducing a lightweight PointNet layer *after* the sparse convs to fuse BEV features back into the original points for refinement ($\text{PointRCNN}$ style).
3.  **Tracking Integration:** Moving from a single-frame detector to a full $\text{MOT}$ (Multi-Object Tracking) system.
