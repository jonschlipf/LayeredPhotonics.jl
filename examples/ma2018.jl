
"""
Zhijie Ma, Yi Li, Yang Li, Yandong Gong, Stefan A. Maier, and Minghui Hong,
"All-dielectric planar chiral metasurface with gradient geometric phase,"
Opt. Express 26, 6067-6078 (2018)
"""
#Figure 2 A
using RigorousCoupledWaveAnalysis

#required materials
ge=InterpolPerm(RigorousCoupledWaveAnalysis.ge_nunley) #Ge from interpolated measured values
ox=ModelPerm(RigorousCoupledWaveAnalysis.sio2_malitson) #SiO2 from dispersion formula
air=ConstantPerm(1.0) #superstrate material is air

#parameters of structure and kgrid
N=6 #accuracy
wls=1300:5:2000.0 #wavelength axis
a=900.0 #cell size
lmid=615/a #length of main arm
larm=410/a #length of side arms
w=205/a #width of arms
use_cuda=true

function zshapegeo(lmid,larm,w) #parametrized z-shaped unit cell
    cent=Rectangle(w,lmid) #center arm
    top=Shift(Rectangle(larm-w,w),.5larm,lmid/2-w/2) #top arm
    bottom=Shift(Rectangle(larm-w,w),-.5larm,-lmid/2+w/2) #bottom arm
    return Combination([cent,top,bottom]) #combine them
end

#forward propagation
geo=zshapegeo(lmid,larm,w) #call the method
act=PatternedLayer(500,[air,ge],[geo]) #the active layer is air with Ge structures, 500 nm thick
mdl=RCWAModel([act],air,ox) #build the model, with superstrate and substrate material
Rrf=zeros(length(wls)) #Forward rcp reflectivity
Trf=zeros(length(wls)) #Forward rcp transmissivity
Rlf=zeros(length(wls)) #Forward lcp reflectivity
Tlf=zeros(length(wls)) #Forward lcp transmissivity
@time for i in eachindex(wls) #iterate over all wavelengths
    λ=wls[i] #get wavelength from array
    grd=rcwagrid(N,N,a,a,1E-5,0,λ,air,use_cuda) #build a reciprocal space grid
    ste,stm=rcwasource(grd,1) #define source
    Rlf[i],Tlf[i]=etm_reftra(sqrt(.5)*(stm+1im*ste),mdl,grd,λ) #lcp propagation
    Rrf[i],Trf[i]=etm_reftra(sqrt(.5)*(1im*stm+ste),mdl,grd,λ) #rcp propagation
end

#now invert it
function zshapegeo(lmid,larm,w) #parametrized z-shaped unit cell
    cent=Rectangle(w,lmid) #center arm
    top=Shift(Rectangle(larm-w,w),.5larm,-lmid/2+w/2) #top arm
    bottom=Shift(Rectangle(larm-w,w),-.5larm,lmid/2-w/2) #bottom arm
    return Combination([cent,top,bottom]) #combine them
end
#backward propagation, flip device
geo=zshapegeo(lmid,larm,w) #inverted structure
act=PatternedLayer(500,[air,ge],[geo])
mdl=RCWAModel([act],ox,air) #model is now inverted
Rrb=zeros(length(wls))#Backward rcp reflectivity
Trb=zeros(length(wls))#Backward rcp transmissivity
Rlb=zeros(length(wls))#Backward lcp reflectivity
Tlb=zeros(length(wls))#Backward lcp transmissivity
@time for i in eachindex(wls)
    λ=wls[i]
    grd=rcwagrid(N,N,a,a,1E-5,0,λ,air)
    ste,stm=rcwasource(grd,1)
    Rlb[i],Tlb[i]=etm_reftra(sqrt(.5)*(stm+1im*ste),mdl,grd,λ)
    Rrb[i],Trb[i]=etm_reftra(sqrt(.5)*(1im*stm+ste),mdl,grd,λ)
end
