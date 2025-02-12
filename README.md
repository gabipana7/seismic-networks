## seismic-networks-julia-dev

## DEVELOPMENT 
### This project aims to describe Seismic Regions using elements of Complex Networks
### This is an enhanced Julia port of the original project done in Python

---
# Exploratory Data Analysis
For an extensive review of the data collection and cleaning process, as well as graphical exploration of the data, codes and figures are presented in the complementary project: https://github.com/gabipana7/seismic-exploratory-data-analysis

---
# Network Generation
![Image](https://github.com/user-attachments/assets/06637b91-7a3e-4af6-9da9-47a5c1793475)
First of all networks are generated and their connectivity distribution is analyzed.

![Image](https://github.com/user-attachments/assets/1a388e05-6109-4e44-b0f7-45353c0ff3a4)
This is done with *networks_parameter_dependency.jl*

![Image](https://github.com/user-attachments/assets/8c96001a-d0cd-479b-b689-c239f417f67b)
![Image](https://github.com/user-attachments/assets/e64e2a77-e415-4dd8-9d35-b7b49251331a)
![Image](https://github.com/user-attachments/assets/73eaf63a-312d-4ec7-904c-eb76efc5a0f9)
![Image](https://github.com/user-attachments/assets/fe8b3be3-bff9-4769-b3d6-ccdafea91da2)
Networks with scale-free connectivity distribution 
---
# Netwoks and Motifs Generation
With *networks_generator.jl* networks are generated for the best cube sizes, obtained from the parameter dependency.

With *motifs_generator.jl* triangle and tetrahedron motifs are generated for these networks, with a cutoff for micro-earthquakes (data is trimmed to satisfy that magnitude > 2). 

This computation is done with a slightly adapted Python version of the Nemomap software (https://github.com/zicanl/NemoMapPy)


---
# Motifs Analysis
With *motifs_analysis.jl* the motifs are analyzed as such:

Triangles
- the area of each individual motif is calculated
- for each individual motif, the total (and mean) energy released by the earthquakes that occured in each of its nodes is computed
- for each individual motif, the area is weighted by its total(mean) energy
- the distribution of the results is computed and analyzed with the Python Powerlaw package

![Image](https://github.com/user-attachments/assets/dd12abb3-c7ed-42d6-ae5d-bb5ec383101e)
![Image](https://github.com/user-attachments/assets/1ecda3ab-28fb-4950-b26e-05470393e972)
![Image](https://github.com/user-attachments/assets/9a1d7c9f-d802-411e-bb62-43a0cfabc270)
![Image](https://github.com/user-attachments/assets/df542682-44b5-493f-9368-ca4279aa125e)

Tetrahedrons
- the volume of each individual motif is calculated
- for each individual motif, the total (and mean) energy released by the earthquakes that occured in each of its nodes is computed
- for each individual motif, the volume is weighted by its total(mean) energy
- the distribution of the results is computed and analyzed with the Python Powerlaw package

![Image](https://github.com/user-attachments/assets/c248f8a1-6d03-488f-9a91-9faf41172abe)
![Image](https://github.com/user-attachments/assets/29b7f944-057a-4a49-bfc7-676627d6dfb1)
![Image](https://github.com/user-attachments/assets/ed53fef1-82ed-461c-a1bf-ea5b97a46178)
![Image](https://github.com/user-attachments/assets/e4e2ed29-d43e-4951-96dd-93dd3ba9eb64)

---
This repository represents the toolbox support of our scientific article available at: https://www.sciencedirect.com/science/article/abs/pii/S0378437123008567

Cite as:

Gabriel Tiberiu Pană, Alexandru Nicolin-Żaczek, Motifs in earthquake networks: Romania, Italy, United States of America, and Japan, Physica A: Statistical Mechanics and its Applications, Volume 632, Part 1, 2023, 129301, ISSN 0378-4371, https://doi.org/10.1016/j.physa.2023.129301

