#ifndef WITH_CMAKE
#include "ester-config.h"
#endif
#include "utils.h"
#include "star.h"
#include <omp.h>

// constructor from scratch
star_evol::star_evol() : star2d() {

	check_map_enable = false;

	// Not needed, just to avoid warnings of the compiler
	delta = 0.;
	lnR0 = log(R);
	drhocdX = 0;
	lnrhoc0 = 0.;
	lnpc0 = 0.;
	lnTc0 = 0.;
	mH0 = 0.; // total mass of hydrogen to monitor the consumption of H
	mH = 0.;
}

star_evol::star_evol(const star2d &A) : star2d(A) {
// constructor from a star2d object

	check_map_enable = false;

	// Not needed, just to avoid warnings of the compiler
	delta = 0.;
	lnR0 = log(R);
	drhocdX = 0;
	lnrhoc0 = 0.;
	lnpc0 = 0.;
	lnTc0 = 0.;
	mH0 = 0.;
	mH = 0.;
}

star_evol::star_evol(const star_evol &A) : star2d(A) {
	copy(A);
}

star_evol &star_evol::operator=(const star_evol &A) {
	star2d::copy(A);
	copy(A);
	return *this;
}

void star_evol::copy(const star_evol &A) {
	Xprev = A.Xprev;
	//XNprev = A.XNprev;
	XOprev = A.XOprev;
	XCprev = A.XCprev;
	r0 = A.r0;
	rho0 = A.rho0;
	T0 = A.T0;
	lnp0 = A.lnp0;
	lnR0 = A.lnR0;
	drhocdX = A.drhocdX;
	lnrhoc0 = A.lnrhoc0;
	lnTc0 = A.lnTc0;
	lnpc0 = A.lnpc0;
	delta = A.delta;
	check_map_enable = A.check_map_enable;
	mH0 = A.mH0;
	mH = A.mH;
	age = A.age;
	N2_prev = A.N2_prev;

	dXdt = A.dXdt;
	drhodt = A.drhodt;
	dpdt = A.dpdt;
	dwdt = A.dwdt;
	dTdt = A.dTdt;
	dphidt = A.dphidt;
}

void star_evol::read_vars(INFILE *fp) {
// just work for binary files not .h5 files (yet)
	if(fp->read("dXdt", &dXdt)) dXdt = zeros(nr, nth);
	if(fp->read("drhodt", &drhodt)) drhodt = zeros(nr, nth);
	if(fp->read("dpdt", &dpdt)) dpdt = zeros(nr, nth);
	if(fp->read("dwdt", &dwdt)) dwdt = zeros(nr, nth);
	if(fp->read("dTdt", &dTdt)) dTdt = zeros(nr, nth);
	if(fp->read("dphidt", &dphidt)) dphidt = zeros(nr, nth);

	fill();

}

void star_evol::write_vars(OUTFILE *fp) const {
// just work for binary files not .h5 files (yet)
	fp->write("dXdt", &dXdt);
	fp->write("drhodt", &drhodt);
	fp->write("dpdt", &dpdt);
	fp->write("dwdt", &dwdt);
	fp->write("dTdt", &dTdt);
	fp->write("dphidt", &dphidt);
}

void star_evol::fill() {

	star2d::fill();

	Omega_bk=Omega/Omegac;
	mH = 2*PI*rhoc*R*R*R*(map.I, rho*comp["H"]*r*r*map.rz, map.It)(0);


}

void star_evol::calcTimeDerivs() {
// Compute the time derivatives just for output
	static symbolic S;
	static sym derivt;
	static bool sym_inited = false;
	if (!sym_inited) {
		sym val = S.regvar("val");
		sym val0 = S.regvar("val0");
		sym lnR = S.regconst("log_R");
		sym R = exp(lnR);
		sym r = S.r;
		sym r0 = S.regvar("r0");
		sym lnR0 = S.regconst("log_R0");
		sym delta = S.regconst("delta");
		sym drdt = (r-r0)/delta;
		sym dlnRdt = (lnR-lnR0)/delta;
		derivt = (val-val0)/delta - (drdt+r*dlnRdt)/S.rz*Dz(val);
		sym_inited = true;
	}

	S.set_value("log_R", log(R)*ones(1,1));
	S.set_value("delta", delta*ones(1,1));
	S.set_value("log_R0", lnR0*ones(1,1));
	S.set_value("r0", r0);
	S.set_map(map);

	S.set_value("val", comp["H"]);
	S.set_value("val0", Xprev);
	dXdt = derivt.eval(); // as evluated by the RK method

	S.set_value("val", rho);
	S.set_value("val0", rho0);
	drhodt = rhoc * (derivt.eval() + rho*(log(rhoc) - lnrhoc0)/delta);

	S.set_value("val", log(p));
	S.set_value("val0", lnp0);
	dpdt = pc * (p*derivt.eval() + p*(log(pc) - lnpc0)/delta);

	S.set_value("val", w);
	S.set_value("val0", w0);
	dwdt = units.Omega * (derivt.eval() + w*0.5*(log(pc) - lnpc0)/delta - w*0.5*(log(rhoc) - lnrhoc0)/delta - w*(log(R) - lnR0)/delta);

	S.set_value("val", T);
	S.set_value("val0", T0);
	dTdt = Tc * (derivt.eval() + T*(log(Tc) - lnTc0)/delta);

	S.set_value("val", phi);
	S.set_value("val0", phi0);
	dphidt = units.phi * (derivt.eval() + phi*(log(pc) - lnpc0)/delta - phi*(log(rhoc) - lnrhoc0)/delta);

}

void star_evol::init_comp() {

}

solver * star_evol::init_solver(int nvar_add) { // initialisation of solver
	return star2d::init_solver(nvar_add+6); // add 5 variables
}

void star_evol::register_variables(solver *op) {
// the 4 additional variables
	star2d::register_variables(op);
	op->regvar("X");
	op->regvar("XO");
	op->regvar("XC");
	op->regvar("Xc");
	op->regvar("log_M");
	op->regvar("reg_cont");

}

void star_evol::write_eqs(solver *op) {
#ifdef MKL
	int mkl_threads = mkl_get_max_threads();
	mkl_set_num_threads(1);   // Faster with 1 thread !?
#endif
#ifdef THREADS
	int num_threads = 3;
	std::thread t[num_threads];
	t[0] = std::thread(&star_evol::solve_X, this, op);
	t[1] = std::thread(&star_evol::solve_XO, this, op);
	t[2] = std::thread(&star_evol::solve_XC, this, op);

#else
	solve_X(op);
	solve_XO(op);
	solve_XC(op);

#endif
	star2d::write_eqs(op);
#ifdef THREADS
	for(int i=0; i< num_threads; i++)
		t[i].join();
#endif
#ifdef MKL
	mkl_set_num_threads(mkl_threads);
#endif
}

double star_evol::update_solution(solver *op, double &h, matrix_map& error_map, int nit) {
	double dmax=config.newton_dmax;

	matrix dX = op->get_var("X");
	matrix dXO = op->get_var("XO");
	matrix dXC = op->get_var("XC");
	while(exist(abs(h*dX)>dmax)) h /= 2;
	double h2 = h/2;

	double err = star2d::update_solution(op, h, error_map, 0); // call of star2d part

	dX = max(dX, -comp["H"]/h);
	double err2 = max(abs(dX));
	err=err2>err?err2:err;
	//comp["He4"] -= h*dX;
	comp["H"] += h*dX;

	if (comp.Z()(0,0)<2.5e-3){

		//printf(", dXN_before_max = %e, -comp['N14']/h = %e , h = %e ",dXN(0,0),-comp["N14"](0,0)/h,h);
		//dXN =max(dXN, -comp["N14"]/h); // this part doesn't seem to be anywhere else in the code. Now why is that. 
		//printf(", dXN_after_max = %e ",dXN(0,0));		
		printf(", nit = %i",nit);
		
		if(dXN(0,0) <0){ // dXN can't be negative, or can it because of mixing? 
		dXN=dXN*0;
		}
		
		if(nit >1&&dXN(0,0) >0) {
		printf(" if statment condition called ");
			dXN =dXN*0;
		}
	}

	// The error of the solution is only based on the error from the hydrogen-mass fraction profile. 
	// We assume all O16 that reacted is converted into N14, as the intermediate reactions are fast.
<<<<<<< Updated upstream
=======
<<<<<<< HEAD
	printf(", dXN = %.6e, N14 = %.6e", dXN(0,0), comp["O16"](0,0)*AMASS["N14"]/AMASS["O16"]);
	dXN = min(dXN, comp["O16"]*AMASS["N14"]/AMASS["O16"]);
	comp["O16"] -= h*dXN*AMASS["O16"]/AMASS["N14"];
	comp["N14"] += h*dXN;	
=======
>>>>>>> Stashed changes
	
	dXO = max(dXO, -comp["O16"]/h);
	err2 = max(abs(dXO));
	err=err2>err?err2:err;

	dXC = max(dXC, -comp["C12"]/h); // Because the destruction of C12 happens on such a short time scale, prevent the solver from keeping on mixing C12 in the core.
	if (nit > 1 && dXC(0,0) > 0) {
		dXC = dXC*0;
	} 
	matrix dXN = -(dXO*AMASS["N14"]/AMASS["O16"]+dXC*AMASS["N14"]/AMASS["C12"]);
	//printf("dXN = %e, dXC = %e, dXO = %e ", dXN(0,0), dXO(0,0), dXC(0,0));
	//printf("sum CNO = %e \n", comp["N14"](0,0) + comp["O16"](0,0) + comp["C12"](0,0));
	//dXN = min(dXN, comp["O16"]*AMASS["N14"]/AMASS["O16"]);
	//printf("dXN = %e, N14 = %e, dXO = %e, O16 = %e, dXC = %e, C12 = %e \n", dXN(0,0), comp["N14"](0,0), dXO(0,0), comp["O16"](0,0), dXC(0,0), comp["C12"](0,0));

	// comp["O16"] -= h*dXN*AMASS["O16"]/AMASS["N14"];
	// comp["N14"] += h*dXN;


	comp["N14"] += h*dXN;
	comp["O16"] += h2*dXO;
	comp["C12"] += h*dXC;

	matrix dY = -(dX + dXN + (h2/h)*dXO + dXC);
	comp["He4"] += h*dY;

	printf("core: dX = %e, dY = %e, dXC = %e, dXN = %e, dXO = %e \n", h*dX(0,0), h*dY(0,0), h*dXC(0,0), h*dXN(0,0), h2*dXO(0,0));
	printf("max:  dX = %e, dY = %e, dXC = %e, dXN = %e, dXO = %e \n", max(abs(h*dX)), max(abs(h*dY)), max(abs(h*dXC)), max(abs(h*dXN)), max(abs(h2*dXO)));
	printf("       X = %e,  Y = %e,  XC = %e,  XN = %e,  XO = %e \n", comp["H"](0,0), comp["He4"](0,0), comp["C12"](0,0), comp["N14"](0,0), comp["O16"](0,0));

	double deltaM; // Mass loss rate in Msun/yr.
	//double lum, Teff; //luminosity.
	//double secyear=MYR/1e6;
	//double Z_SUN = 0.013; // Value used by Björklund et al. (2021) for fit to their models. (See below)
	//matrix Fz=-opa.xi*(map.gzz*(D,T)+map.gzt*(T,Dt));
	//lum=2*PI*((Fz*r*r*map.rz).row(nr-1),map.leg.I_00)(0)*units.T*units.r;
	matrix F=-opa.xi/sqrt(map.gzz)*(map.gzz*(D,T)+map.gzt*(T,Dt))/units.r*units.T;
	F=F.row(nr-1)/SIG_SB;
	//Teff = pow(F,0.25)(0);
	//Mdot = pow(10, -5.52 + 2.39*log10(lum/(1e6*L_SUN)) - 1.48*log10(M/(45*M_SUN)) + 2.12*log10(Teff/45e3) + (0.75-1.87*log10(Teff/45e3))*log10(Z0/Z_SUN));
	//Mdot = pow(10, -5.55+0.79*log10(Z0/0.013)+(2.16-0.32*log10(Z0/0.013))*log10(lum/(1e6*L_SUN))); // Formula from eq. (20) of Björklund et al. (2021, Astronomy & Astrophysics, Volume 648, id.A36).
	double M_dot, delta_CAK, kap_el;
	matrix alpha1, alpha2, alpha, alpha_prime, flux, mdot, vth, Teff_;
	Teff_ = pow(F,0.25); //Teff();
	flux = pow(Teff_,4)*SIG_SB;
	printf("F = %e\n", min(F));
	vth = pow(2*K_BOL*Teff_/(AMASS["Fe56"]*UMA), 0.5);
	matrix geff = abs(gsup());
	delta_CAK = 0.1;

	double E_CHARGE = 4.803e-10; // statcoulombs
	double M_ELEC = 9.109e-28; // grams

	double Z_SUN = 0.016; //0.02;

	alpha = ones(1,nth);
	alpha1 = ones(1,nth);
	alpha2 = ones(1,nth);
	mdot = zeros(1,nth);

	// Alpha(Teff) relation for Z/Zsun = 1.
	for (int k=0; k < nth; k++){
		if (Teff_(k) < 10000){
			alpha1(k) = 0.45;
		}
		else if (Teff_(k) >= 10000 && Teff_(k) < 20000){
			alpha1(k) = 1e-5*Teff_(k)+0.3;
		}
		else if (Teff_(k) >= 20000 && Teff_(k) < 40000){
			alpha1(k) = 5e-6*Teff_(k)+0.5;
		}
		else {
			alpha1(k) = 0.70;
		}						 
	}

	// Alpha(Teff) relation for Z/Zsun = 0.1.
	for (int k=0; k < nth; k++){
		if (Teff_(k) < 10000){
			alpha2(k) = 0.38;
		}
		else if (Teff_(k) >= 10000 && Teff_(k) < 20000){
			alpha2(k) = 1.6e-5*Teff_(k)+0.22;
		}
		else if (Teff_(k) >= 20000 && Teff_(k) < 40000){
			alpha2(k) = 5.5e-6*Teff_(k)+0.43;
		}
		else {
			alpha2(k) = 0.65;
		}						 
	}
	alpha = (alpha1 - alpha2) * log10(Z0/Z_SUN) + alpha1;
	alpha_prime =  alpha - delta_CAK;

	for (int k=0; k < nth; k++){
		kap_el = 0.2*(1+comp.X()(-1,k)); // cm^2/g
		mdot(k) = (4.0/9.0)*alpha(k)/(vth(k)*C_LIGHT)*pow((C_LIGHT/(kap_el*(1-alpha(k))))*(geff(k) - kap_el*flux(k)/C_LIGHT),(alpha_prime(k)-1)/alpha_prime(k)) * pow(flux(k), 1/alpha_prime(k))*(MYR/1e6);
	}

	M_dot = 2*PI*((mdot*r*map.rz).row(nr-1),map.leg.I_00)(0)*units.r*units.r/M_SUN;
	double k_cal = 1.277873e-03; //10Msun Z=0.016

	deltaM =  k_cal*M_dot*M_SUN*delta*1e6;
<<<<<<< Updated upstream
=======
>>>>>>> e99e554dffc7ea82a9598696159e1a5b0b543514
>>>>>>> Stashed changes

// Rem: the conservationn of total mass is insured by the mass conservation equation
// as ang. Mom.
	//M *= exp(h*op->get_var("log_M")(0));
	//printf("nit = %i, M = %e Msun, deltaM = %e Msun, Mdot = %e Msun/yr, Teff = %e\n", nit, M/M_SUN, deltaM/M_SUN, M_dot, max(Teff_));
	if (nit == 1){
		M += deltaM; // Account for mass loss at the first iteration.
		printf("M = %e Msun, deltaM = %e Msun, Mdot = %e Msun/yr\n",M/M_SUN, deltaM/M_SUN, M_dot);
	}


	return err;
}

// Functions to initialize the time-stepper
SDIRK_solver* star_evol::init_time_solver() {
	SDIRK_solver *rk = new SDIRK_solver();
	//rk->init(13, "be"); //sdirk3, be
	rk->init(14, "be"); //sdirk3, be
	register_variables(rk);
	return rk;
}

void star_evol::register_variables(SDIRK_solver *rk) {
// check_map is call only once at every time step
	check_map_enable = true;
	check_map();
	check_map_enable = false;

	rk->regvar("X", comp.X());
	//rk->regvar("XN", comp["N14"]);
	rk->regvar("XO", comp["O16"]);
	rk->regvar("XC", comp["C12"]);
	rk->regvar("lnR", log(R)*ones(1,1));
	rk->regvar("r", r);
	rk->regvar("rho", rho);
	rk->regvar("log_rhoc", log(rhoc)*ones(1,1));
	rk->regvar("T", T);
	rk->regvar("log_Tc", log(Tc)*ones(1,1));
	rk->regvar("log_p", log(p));
	rk->regvar("log_pc", log(pc)*ones(1,1));
	rk->regvar("w", w);
	rk->regvar("phi", phi); // not used in the time-stepping but used for output
	rk->regvar("N2", N2());
}

void star_evol::init_step(SDIRK_solver *rk) {
// used at every time step
	delta = rk->get_delta();
	age = rk->get_t();

	Xprev = rk->get_var("X");
	//XNprev = rk->get_var("XN");
	XOprev = rk->get_var("XO");
	XCprev = rk->get_var("XC");
	r0 = rk->get_var("r");
	lnR0 = rk->get_var("lnR")(0);
	rho0 = rk->get_var("rho");
	lnrhoc0 = rk->get_var("log_rhoc")(0);
	T0 = rk->get_var("T");
	lnTc0 = rk->get_var("log_Tc")(0);
	lnp0 = rk->get_var("log_p");
	lnpc0 = rk->get_var("log_pc")(0);
	w0 = rk->get_var("w");
	phi0 = rk->get_var("phi");
	N2_prev = rk->get_var("N2");
}

void star_evol::finish_step(SDIRK_solver *rk, int state) {
// finish the time step after the Newton iteration
	if (state == RK_STEP) { // check_map is call only once in the 3 steps of the RK time-step
		check_map_enable = true;
		check_map();
		check_map_enable = false;
	}

	rk->set_var("X", comp.X());
	//rk->set_var("XN", comp["N14"]);
	rk->set_var("XO", comp["O16"]);
	rk->set_var("XC", comp["C12"]);
	rk->set_var("r", map.r);
	rk->set_var("lnR", log(R)*ones(1,1));
	rk->set_var("rho", rho);
	rk->set_var("log_rhoc", log(rhoc)*ones(1,1));
	rk->set_var("T", T);
	rk->set_var("log_Tc", log(Tc)*ones(1,1));
	rk->set_var("log_p", log(p));
	rk->set_var("log_pc", log(pc)*ones(1,1));
	rk->set_var("w", w);
	rk->set_var("phi", phi);
	rk->set_var("N2", N2());

}

void star_evol::reset_time_solver(SDIRK_solver *rk) {
// Needed for a restart
	finish_step(rk, -1);
	rk->reset();
}


void star_evol::check_map() {
	if (!check_map_enable) return;
	else star2d::check_map();
}

void star_evol::interp(remapper *red) {
	star2d::interp(red);
}

void star_evol::calc_units() {
	star2d::calc_units();
	units.v = R / MYR;
}

void star_evol::solve_definitions(solver *op) {

    star2d::solve_definitions(op);

    composition_map comp2(comp);
    comp2["H"] += 1e-4;
    comp2["He4"] -= 1e-4;

    eos_struct eos2;
    matrix rho2;
    strcpy(eos2.name, eos.name);
    //eos_calc(comp2.X(), Z0, T*Tc, p*pc, rho2, eos2);
    eos_calc(comp2.X(), comp2.Z(), T*Tc, p*pc, rho2, eos2);
// Derivative with respect to X, should be in physics...
    matrix drhodX = (rho2/rhoc - rho)/1e-4;
    drhocdX = (rho2(0,0) - rhoc) / 1e-4;
    op->add_d("rho", "X", drhodX);
    //op->add_d("eos.cp", "X", (eos2.cp - eos.cp) / 1e-4);
    //op->add_d("eos.del_ad", "X", (eos2.del_ad - eos.del_ad) / 1e-4);

    opa_struct opa2;
    strcpy(opa2.name, opa.name);
    //opa_calc(comp2.X(), Z0, T*Tc, rho*rhoc, opa2);
    opa_calc(comp2.X(), comp2.Z(), T*Tc, rho*rhoc, opa2);
    matrix dxidX = (opa2.xi - opa.xi) / 1e-4;
    op->add_d("opa.xi", "X", dxidX);

    nuc_struct nuc2;
    strcpy(nuc2.name, nuc.name);
    nuc_calc(comp2, T*Tc, rho*rhoc, nuc2);
    matrix depsdX = (nuc2.eps - nuc.eps) / 1e-4;
    op->add_d("nuc.eps", "X", depsdX);

    for(int n=0; n<ndomains; n++) {
    	op->add_d(n, "log_rhoc", "Xc", drhocdX/rhoc*ones(1,1));
    }
}


void star_evol::solve_dim(solver *op) {

	star2d::solve_dim(op);

	op->add_d(ndomains-1, "log_R", "log_M", -ones(1,1));

}

void star_evol::solve_Omega(solver *op) {
// Needed for "programming" reasons....

	matrix rhs;
	int n;
	
	rhs=zeros(ndomains, 1);
	for(n=0; n<ndomains-1; n++) {
		op->bc_top1_add_d(n, "Omega", "Omega", ones(1,1));
		op->bc_top2_add_d(n, "Omega", "Omega", -ones(1,1));
	}

	n = ndomains-1;

	if (Omega == 0) {
		op->bc_top1_add_d(n, "Omega", "Omega", ones(1,1));
	}
	else {
		matrix TT;
		map.leg.eval_00(th, PI/2, TT);
		op->bc_top1_add_d(n, "Omega", "Omega", ones(1,1));
		op->bc_top1_add_r(n, "Omega", "w", -ones(1,1), TT);
		rhs(n) = -Omega + (w.row(-1), TT)(0);
	}
	op->set_rhs("Omega", rhs);
}

void star_evol::solve_X(solver *op) {
    double Q=(4*HYDROGEN_MASS-AMASS["He4"]*UMA)*C_LIGHT*C_LIGHT;
    double diff_coeff_conv = 1e13; // Set the chemical diffusion coefficient in the core to a large value such that no chemical imhomogenities develop in the convective core. 

    static symbolic S;
    static sym eq, flux, gradX;
    static bool sym_inited = false;
    if (!sym_inited) {
    	sym X = S.regvar("X");
    	sym eps = S.regvar("nuc.eps");
    	sym rho = S.regvar("rho");
    	sym vr = S.regvar("vr");
    	sym vt = S.regvar("vt");
    	sym lnR = S.regconst("log_R");
    	sym R = exp(lnR);
    	sym r = S.r;
    	sym X0 = S.regvar("X0");
    	sym r0 = S.regvar("r0");
    	sym lnR0 = S.regconst("log_R0");
    	sym delta = S.regconst("delta");
    	sym Dv = S.regvar("diffusion_v");
    	sym Dh = S.regconst("diffusion_h");
    	sym sin_vangle = S.regvar("sin_vangle");
    	sym cos_vangle = S.regvar("cos_vangle");
    	sym MYR = S.regconst("MYR");
    	sym mH = S.regconst("mH");
    	sym Q = S.regconst("Q");



    	sym_vec phivec(COVARIANT);
    	phivec(0) = 0*S.one; phivec(1) = 0*S.one; phivec(2) = S.r*sin(S.theta);
    	sym_vec rvec = grad(S.r);
    	sym_vec thvec = cross(phivec, rvec);

    	sym_vec rhoV = rho*(vr*rvec + vt*thvec);

    	sym drdt = (r-r0)/delta;
    	sym dlnRdt = (lnR-lnR0)/delta;
    	sym dXdt = (X-X0)/delta - (drdt+r*dlnRdt)/S.rz*Dz(X);

    	sym_vec v_vec = cos_vangle*rvec - sin_vangle*thvec;
    	sym_vec h_vec = sin_vangle*rvec + cos_vangle*thvec;
    	sym_tens D = tensor(v_vec, v_vec)*Dv + tensor(h_vec, h_vec)*Dh;

    	eq = dXdt + 4*mH*MYR/Q*eps - MYR/R/R * div(rho*(D, grad(X)))/rho + (rhoV, grad(X))/rho; 
    	sym_vec nvec = grad(S.zeta);
    	nvec = nvec / sqrt((nvec, nvec));
    	flux = - MYR/R/R*(nvec, (D, grad(X)));
    	gradX = (nvec, grad(X));
    	sym_inited = true;
    }

    S.set_value("X", comp.X());
    S.set_value("nuc.eps", nuc.eps);
    S.set_value("rho", rho);
    S.set_value("vr", vr);
    S.set_value("vt", vt, 11);
    S.set_value("log_R", log(R)*ones(1,1));
    S.set_value("delta", delta*ones(1,1));
    S.set_value("X0", Xprev);
    S.set_value("log_R0", lnR0*ones(1,1));
    S.set_value("r0", r0);
    S.set_value("MYR", MYR*ones(1,1));
    S.set_value("mH", HYDROGEN_MASS*ones(1,1));
    S.set_value("Q", Q*ones(1,1));
    S.set_value("sin_vangle", sin(vangle), 11);
    S.set_value("cos_vangle", cos(vangle));

    S.set_map(map);

	matrix K;
	K = opa.xi/(rho*units.rho*eos.cp);
	matrix dOmega_dr, Dmix_v_mean;
	dOmega_dr  = (map.gzz*(D,w)+map.gzt*(w,Dt))/sqrt(map.gzz);  
	matrix Dmix_v;
	Dmix_v_mean = zeros(nr,1);
	for (int l=0; l < nr; l++){
		for (int k=0; k < nth; k++){
			Dmix_v_mean(l) += K(l,k)*r(l,k)*r(l,k)*dOmega_dr(l,k)*dOmega_dr(l,k); 
		}
	}
	Dmix_v_mean /= nth;

	Dmix_v = diffusion_v*Dmix_v_mean*units.Omega*units.Omega;

    matrix diff_v = ones(nr, nth) * diffusion_v;
    matrix diff_h = ones(nr, nth) * diffusion_h;

    if (conv) {
// Diffusion in the core which is enhanced!!
    	int nc = 0;
    	for (int n = 0; n < conv; n++) nc += map.npts[n];
    	diff_v.setblock(0, nc-1, 0, -1, ones(nc, nth) * diff_coeff_conv);
    	diff_h.setblock(0, nc-1, 0, -1, ones(nc, nth) * diff_coeff_conv);


		if (max(dOmega_dr) > 0){
			for (int j = nc; j < nr; j++) {			
						if (N2()(j,0) <= 0) {
							if (j > nc+10){
							int n = 0, ne = 0;
    						while (1) {
								if (ne + map.npts[n] < j) {
									ne += map.npts[n];
									n++;
								}
								else{
									break;
								}
							}
							diff_v.setblock(ne, -1, 0, -1, ones(nr-ne,nth) * Dmix_v(ne-1));
							break;
							}
						}
						diff_v.setblock(j, j, 0, -1, ones(1,nth) * Dmix_v(j));

			}
		}
    }

    S.set_value("diffusion_v", diff_v);
    S.set_value("diffusion_h", diff_h);


    eq.add(op, "X", "X");
    eq.add(op, "X", "nuc.eps");
    eq.add(op, "X", "rho");
    eq.add(op, "X", "log_R");
    eq.add(op, "X", "r");
    eq.add(op, "X", "vr");
    eq.add(op, "X", "vt");
    eq.add(op, "X", "sin_vangle");
    eq.add(op, "X", "cos_vangle");

    matrix rhs=-eq.eval();
    matrix X = comp.X();
    matrix dX = (D, X);
    matrix flux_val = flux.eval();
    matrix gradX_val = gradX.eval();

    int j0 = 0;
    for (int n = 0; n < ndomains; n++) {
    	int j1 = j0 + map.npts[n] - 1;

    	if (n == conv && conv > 0) {
    		flux.bc_bot2_add(op, n, "X", "X");
    		flux.bc_bot2_add(op, n, "X", "r");
    		flux.bc_bot1_add(op, n, "X", "X", -ones(1,nth));
    		flux.bc_bot1_add(op, n, "X", "r", -ones(1,nth));
    		rhs.setrow(j0, - flux_val.row(j0) + flux_val.row(j0-1));
    	}
    	else {
    		op->bc_bot2_add_l(n, "X", "X", 1./map.rz.row(j0), D.block(n).row(0));
    		op->bc_bot2_add_d(n, "X", "rz", -1./map.rz.row(j0)/map.rz.row(j0)*dX.row(j0));
    		rhs.setrow(j0, -dX.row(j0)/map.rz.row(j0)) ;
    		if (n) {
    			op->bc_bot1_add_l(n, "X", "X", -1./map.rz.row(j0-1), D.block(n-1).row(-1));
    			op->bc_bot1_add_d(n, "X", "rz", 1./map.rz.row(j0-1)/map.rz.row(j0-1)*dX.row(j0-1));
    			rhs.setrow(j0, rhs.row(j0) + dX.row(j0-1)/map.rz.row(j0-1));
    		}
    	}
    	if (n < ndomains - 1) {
    		if (n == conv-1) {
    			op->bc_top1_add_d(n, "X", "X", ones(1,nth));
    			op->bc_top2_add_d(n, "X", "X", -ones(1,nth));
    			rhs.setrow(j1, -X.row(j1) + X.row(j1+1));
    		}
    		else {
    			op->bc_top1_add_d(n, "X", "X", ones(1,nth));
    			op->bc_top2_add_d(n, "X", "X", -ones(1,nth));
    			rhs.setrow(j1, -X.row(j1) + X.row(j1+1));
    		}
    	}
    	else {
    		gradX.bc_top1_add(op, n, "X", "X");
    		gradX.bc_top1_add(op, n, "X", "r");
    		rhs.setrow(j1, -gradX_val.row(-1)); // no flux at the surface
    	}
    	j0 += map.npts[n];
    }

    op->set_rhs("X",rhs);


    rhs=zeros(ndomains,1);
// Central X needed for rho_c
    for(int n = 0; n < ndomains; n++) {
    	if(n == 0) {
    		op->bc_bot2_add_d(n, "Xc", "Xc", ones(1,1));
    		op->bc_bot2_add_r(n, "Xc", "X", -ones(1,1), map.It/2.);
    	} else {
    		op->bc_bot2_add_d(n, "Xc", "Xc", ones(1,1));
    		op->bc_bot1_add_d(n, "Xc", "Xc", -ones(1,1));
    	}
    }
    op->set_rhs("Xc", rhs);

}

double rec_NA = 1/6.02214076e23;
double NA = 6.02214076e23;

double lam12(double T9) {
    double result = (2.00e7 / pow(T9, 2.0 / 3) * exp(-13.689 / pow(T9, 1.0 / 3) - pow((T9 / 0.46), 2)) * (1 + 9.89 * T9 - 59.8 * pow(T9, 2) + 266 * pow(T9, 3))
                     + 1e5 / pow(T9, 1.5) * exp(-4.913 / T9)
                     + 4.24e5 / pow(T9, 1.5) * exp(-21.62 / T9)) / NA;
    return result;
}

double lam13(double T9) {
    double result = ((9.57e7 / pow(T9, 2.0 / 3) * (1 + 3.56 * T9) * exp(-13.720 / pow(T9, 1.0 / 3) - pow(T9, 2))
                     + 1.5e6 / pow(T9, 1.5) * exp(-5.93 / T9)
                     + 6.83e5 / pow(T9, 0.864) * exp(-12.057 / T9)) * (1 - 2.07 * exp(-37.938 / T9))) / NA;
    return result;
}

double lam14(double T9) {
    double result = (4.83e7 / pow(T9, 2.0 / 3) * exp(-15.231 / pow(T9, 1.0 / 3) - pow((T9 / 0.8), 2)) * (1 + 2 * T9 - 3.41 * pow(T9, 2) - 2.43 * pow(T9, 3))
                     + 2.36e3 / pow(T9, 1.5) * exp(-3.010 / T9)
                     + 6.72e3 * pow(T9, 0.38) * exp(-9.53 / T9)) / NA;
    return result;
}

double lam15(double T9) {
    double result = (1.12e12 / pow(T9, 2.0 / 3) * exp(-15.253 / pow(T9, 1.0 / 3) - pow((T9 / 0.28), 2)) * (1 + 4.95 * T9 + 143 * pow(T9, 2))
                     + 1.01e8 / pow(T9, 1.5) * exp(-3.643 / T9)
                     + 1.19e9 / pow(T9, 1.5) * exp(-7.406 / T9)) / NA;
    return result;
}

double lam15p(double T9) {
    double result = (1.08e9 / pow(T9, 2.0 / 3) * exp(-15.254 / pow(T9, 1.0 / 3) - pow((T9 / 0.34), 2)) * (1 + 6.15 * T9 + 16.4 * pow(T9, 2))
                     + 9.23e3 / pow(T9, 1.5) * exp(-3.597 / T9)
                     + 3.27e6 / pow(T9, 1.5) * exp(-11.024 / T9)) / NA;
    return result;
}

double lam16(double T9) {
	double result = (7.37e7 / pow(T9, 0.82) * exp(-16.696 / pow(T9, 1.0 / 3))) * (1 + 202 * exp(-70.348 / T9 - 0.161 * T9)) * rec_NA;
	return result;
}

double lam17(double T9) {
    double result = (9.20e8 / pow(T9, 2.0 / 3) * exp(-16.715 / pow(T9, 1.0 / 3) - pow((T9 / 0.06), 2)) * (1 + 80.31 * T9 - 2211 * pow(T9, 2))
                     + 9.13e-4 / pow(T9, 1.5) * exp(-0.7667 / T9)
                     + 9.68 / pow(T9, 1.5) * exp(-2.083 / T9)
                     + 8.13e6 / pow(T9, 1.5) * exp(-5.685 / T9)
                     + 1.85e6 * pow(T9, 1.591) * exp(-4.848 / T9)) * (1 + 1.033 * exp(-10.034 / T9 - 0.165 * T9)) / NA;
    return result;
}

void star_evol::solve_XN(solver *op) {
    double Q=(4*HYDROGEN_MASS-AMASS["He4"]*UMA)*C_LIGHT*C_LIGHT;
    double diff_coeff_conv = 1e13; // PARAMETER dimensional
    static symbolic S;
    static sym eq, flux, gradXN;
    static bool sym_inited = false;
    if (!sym_inited) {
    	sym XN = S.regvar("XN");
		sym X = S.regconst("X");
    	sym rho = S.regvar("rho");
    	sym vr = S.regvar("vr");
    	sym vt = S.regvar("vt");
    	sym lnR = S.regconst("log_R");
    	sym R = exp(lnR);
    	sym r = S.r;
    	sym XN0 = S.regvar("XN0");
    	sym X0 = S.regvar("X0");
    	sym r0 = S.regvar("r0");
    	sym lnR0 = S.regconst("log_R0");
    	sym delta = S.regconst("delta");
    	sym Dv = S.regvar("diffusion_v");
    	sym Dh = S.regconst("diffusion_h");
    	sym sin_vangle = S.regvar("sin_vangle");
    	sym cos_vangle = S.regvar("cos_vangle");
    	sym MYR = S.regconst("MYR");
    	sym mH = S.regconst("mH");
    	sym Q = S.regconst("Q");
		sym dXN14dt = S.regvar("dXN14dt");


    	sym_vec phivec(COVARIANT);
    	phivec(0) = 0*S.one; phivec(1) = 0*S.one; phivec(2) = S.r*sin(S.theta);
    	sym_vec rvec = grad(S.r);
    	sym_vec thvec = cross(phivec, rvec);

    	sym_vec rhoV = rho*(vr*rvec + vt*thvec);

    	sym drdt = (r-r0)/delta;
    	sym dlnRdt = (lnR-lnR0)/delta;
    	sym dXNdt = (XN-XN0)/delta - (drdt+r*dlnRdt)/S.rz*Dz(XN);
    	sym dXdt = (X-X0)/delta - (drdt+r*dlnRdt)/S.rz*Dz(X);

    	sym_vec v_vec = cos_vangle*rvec - sin_vangle*thvec;
    	sym_vec h_vec = sin_vangle*rvec + cos_vangle*thvec;
    	sym_tens D = tensor(v_vec, v_vec)*Dv + tensor(h_vec, h_vec)*Dh;

    	eq = dXNdt - dXN14dt*MYR - MYR/R/R * div(rho*(D, grad(XN)))/rho + (rhoV, grad(XN))/rho; 
    	sym_vec nvec = grad(S.zeta);
    	nvec = nvec / sqrt((nvec, nvec));
    	flux = - MYR/R/R*(nvec, (D, grad(XN)));
    	gradXN = (nvec, grad(XN));
    	sym_inited = true;
    }

    S.set_value("XN", comp["N14"]);
	S.set_value("X", comp.X());
    S.set_value("rho", rho);
    S.set_value("vr", vr);
    S.set_value("vt", vt, 11);
    S.set_value("log_R", log(R)*ones(1,1));
    S.set_value("delta", delta*ones(1,1));
    S.set_value("XN0", XNprev);
	S.set_value("X0", Xprev);
    S.set_value("log_R0", lnR0*ones(1,1));
    S.set_value("r0", r0);
    S.set_value("MYR", MYR*ones(1,1));
    S.set_value("mH", HYDROGEN_MASS*ones(1,1));
    S.set_value("Q", Q*ones(1,1));
    S.set_value("sin_vangle", sin(vangle), 11);
    S.set_value("cos_vangle", cos(vangle));

    S.set_map(map);

	matrix K;
	K = opa.xi/(rho*units.rho*eos.cp);

	matrix dOmega_dr, Dmix_v_mean;
	dOmega_dr  = (map.gzz*(D,w)+map.gzt*(w,Dt))/sqrt(map.gzz); 
	matrix Dmix_v;
	Dmix_v_mean = zeros(nr,1);
	for (int l=0; l < nr; l++){
		for (int k=0; k < nth; k++){
			Dmix_v_mean(l) += K(l,k)*r(l,k)*r(l,k)*dOmega_dr(l,k)*dOmega_dr(l,k); 
		}
	}
	Dmix_v_mean /= nth;

	Dmix_v = diffusion_v*Dmix_v_mean*units.Omega*units.Omega; 
	// diffusion_v presents the eta parameter here. 
	// This a free parameter to account for the fact that the brunt-vaisala frequency is not taken into account in the computation of the vertical diffusion coefficient.

    matrix diff_v = ones(nr, nth) * diffusion_v;
    matrix diff_h = ones(nr, nth) * diffusion_h;

    if (conv) {
// Diffusion in the core which is enhanced!!
    	int nc = 0;
    	for (int n = 0; n < conv; n++) nc += map.npts[n];
    	diff_v.setblock(0, nc-1, 0, -1, ones(nc, nth) * diff_coeff_conv);
    	diff_h.setblock(0, nc-1, 0, -1, ones(nc, nth) * diff_coeff_conv);

		if (max(dOmega_dr) > 0){
			for (int j = nc; j < nr; j++) {			
						if (N2()(j,0) <= 0) {
							if (j > nc+10){
							int n = 0, ne = 0;
    						while (1) {
								if (ne + map.npts[n] < j) {
									ne += map.npts[n];
									n++;
								}
								else{
									break;
								}
							}
							diff_v.setblock(ne, -1, 0, -1, ones(nr-ne,nth) * Dmix_v(ne-1));
							break;
							}
						}
						        diff_v.setblock(j, j, 0, -1, ones(1,nth) * Dmix_v(j));

			}
		}
    }
	
    S.set_value("diffusion_v", diff_v);
    S.set_value("diffusion_h", diff_h);

	// Below, the change in the N14 mass fraction due to nuclear burning is computed. We assume it is dominated by the reaction of O16 to F17, which decays to O17.
	// O17 is then coverted to N14 via O17 + p --> N14 + He4. 
	// The formula for lambda_O16_to_O17 comes from Angulo et al. 1999. (Which is in fact for the reaction of O16 to F17.)

	double rec_NA = 1/6.02214076e23;
	matrix lambda_O16_to_O17 = zeros(nr,nth);
	matrix f = zeros(nr,nth);
	matrix h = zeros(nr,nth);
	matrix L13 = zeros(nr,nth);
	matrix L14 = zeros(nr,nth);
	matrix L17 = zeros(nr,nth);

	for (int i =0; i < nth; i++){
		for (int j = 0; j < nr; j++) {	
				double T9 = T(j,i)/1e9*units.T;
				lambda_O16_to_O17(j,i) =  rec_NA * (7.37e7 * exp(-16.696*pow(T9,-1./3.))*pow(T9,-0.82)); //lam16(T9);
				f(j,i) = lam12(T9)/lam13(T9)*AMASS["C13"]/AMASS["C12"];
				h(j,i) = lam16(T9)/lam17(T9)*AMASS["O17"]/AMASS["O16"];
				L17(j,i) = lam17(T9)/HYDROGEN_MASS;
				L13(j,i) = lam13(T9)/HYDROGEN_MASS;
				L14(j,i) = lam14(T9)/HYDROGEN_MASS;
		}
	}

	matrix nH   = comp["H"]*rho*units.rho/(HYDROGEN_MASS);
	matrix nO16 = comp["O16"]*rho*units.rho/(AMASS["O16"]*UMA); 
	matrix dXN14dt = lambda_O16_to_O17 * nO16 * nH *(AMASS["N14"]*UMA)/(rho*units.rho);
	//matrix dXN14dt = rho*units.rho * comp["H"] *  (-L14*comp["N14"] + f*L13*AMASS["N14"]/AMASS["C13"] * comp["C12"] + h*L17*AMASS["N14"]/AMASS["O17"]*comp["O16"]);
	S.set_value("dXN14dt", dXN14dt);
	printf("dXNdt = %e, Xc = %e, XNc = %e, XOc = %e, XCc = %e \n", dXN14dt(0,0)*MYR, comp["H"](0,0), comp["N14"](0,0), comp["O16"](0,0), comp["C12"](0,0));

    eq.add(op, "XN", "XN");
    eq.add(op, "XN", "rho");
    eq.add(op, "XN", "log_R");
    eq.add(op, "XN", "r");
    eq.add(op, "XN", "vr");
    eq.add(op, "XN", "vt");
    eq.add(op, "XN", "sin_vangle");
    eq.add(op, "XN", "cos_vangle");

    matrix rhs=-eq.eval();
    matrix X = comp["N14"];
    matrix dX = (D, X);
    matrix flux_val = flux.eval();
    matrix gradX_val = gradXN.eval();

    int j0 = 0;
    for (int n = 0; n < ndomains; n++) {
    	int j1 = j0 + map.npts[n] - 1;

    	if (n == conv && conv > 0) {
    		flux.bc_bot2_add(op, n, "XN", "XN");
    		flux.bc_bot2_add(op, n, "XN", "r");
    		flux.bc_bot1_add(op, n, "XN", "XN", -ones(1,nth));
    		flux.bc_bot1_add(op, n, "XN", "r", -ones(1,nth));
    		rhs.setrow(j0, - flux_val.row(j0) + flux_val.row(j0-1));
    	}
    	else {
    		op->bc_bot2_add_l(n, "XN", "XN", 1./map.rz.row(j0), D.block(n).row(0));
    		op->bc_bot2_add_d(n, "XN", "rz", -1./map.rz.row(j0)/map.rz.row(j0)*dX.row(j0));
    		rhs.setrow(j0, -dX.row(j0)/map.rz.row(j0)) ;
    		if (n) {
    			op->bc_bot1_add_l(n, "XN", "XN", -1./map.rz.row(j0-1), D.block(n-1).row(-1));
    			op->bc_bot1_add_d(n, "XN", "rz", 1./map.rz.row(j0-1)/map.rz.row(j0-1)*dX.row(j0-1));
    			rhs.setrow(j0, rhs.row(j0) + dX.row(j0-1)/map.rz.row(j0-1));
    		}
    	}
    	if (n < ndomains - 1) {
    		if (n == conv-1) {
    			op->bc_top1_add_d(n, "XN", "XN", ones(1,nth));
    			op->bc_top2_add_d(n, "XN", "XN", -ones(1,nth));
    			rhs.setrow(j1, -X.row(j1) + X.row(j1+1));
    		}
    		else {
    			op->bc_top1_add_d(n, "XN", "XN", ones(1,nth));
    			op->bc_top2_add_d(n, "XN", "XN", -ones(1,nth));
    			rhs.setrow(j1, -X.row(j1) + X.row(j1+1));
    		}
    	}
    	else {
    		gradXN.bc_top1_add(op, n, "XN", "XN");
    		gradXN.bc_top1_add(op, n, "XN", "r");
    		rhs.setrow(j1, -gradX_val.row(-1)); // no flux at the surface
    	}
    	j0 += map.npts[n];
    }

    op->set_rhs("XN",rhs);


    rhs=zeros(ndomains,1);
// Central X needed for rho_c
//    for(int n = 0; n < ndomains; n++) {
//    	if(n == 0) {
//    		op->bc_bot2_add_d(n, "Xc", "Xc", ones(1,1));
//    		op->bc_bot2_add_r(n, "Xc", "X", -ones(1,1), map.It/2.);
//    	} else {
//    		op->bc_bot2_add_d(n, "Xc", "Xc", ones(1,1));
//    		op->bc_bot1_add_d(n, "Xc", "Xc", -ones(1,1));
//    	}
//    }
//    op->set_rhs("Xc", rhs);

}

void star_evol::solve_XO(solver *op) {
    double Q=(4*HYDROGEN_MASS-AMASS["He4"]*UMA)*C_LIGHT*C_LIGHT;
    double diff_coeff_conv = 1e13; // PARAMETER dimensional
    static symbolic S;
    static sym eq, flux, gradXO;
    static bool sym_inited = false;
    if (!sym_inited) {
    	sym XO = S.regvar("XO");
		sym X = S.regconst("X");
    	sym rho = S.regvar("rho");
    	sym vr = S.regvar("vr");
    	sym vt = S.regvar("vt");
    	sym lnR = S.regconst("log_R");
    	sym R = exp(lnR);
    	sym r = S.r;
    	sym XO0 = S.regvar("XO0");
    	sym X0 = S.regvar("X0");
    	sym r0 = S.regvar("r0");
    	sym lnR0 = S.regconst("log_R0");
    	sym delta = S.regconst("delta");
    	sym Dv = S.regvar("diffusion_v");
    	sym Dh = S.regconst("diffusion_h");
    	sym sin_vangle = S.regvar("sin_vangle");
    	sym cos_vangle = S.regvar("cos_vangle");
    	sym MYR = S.regconst("MYR");
    	sym mH = S.regconst("mH");
    	sym Q = S.regconst("Q");
		sym dXO16dt = S.regvar("dXO16dt");

    	sym_vec phivec(COVARIANT);
    	phivec(0) = 0*S.one; phivec(1) = 0*S.one; phivec(2) = S.r*sin(S.theta);
    	sym_vec rvec = grad(S.r);
    	sym_vec thvec = cross(phivec, rvec);

    	sym_vec rhoV = rho*(vr*rvec + vt*thvec);

    	sym drdt = (r-r0)/delta;
    	sym dlnRdt = (lnR-lnR0)/delta;
    	sym dXOdt = (XO-XO0)/delta - (drdt+r*dlnRdt)/S.rz*Dz(XO);
    	sym dXdt = (X-X0)/delta - (drdt+r*dlnRdt)/S.rz*Dz(X);

    	sym_vec v_vec = cos_vangle*rvec - sin_vangle*thvec;
    	sym_vec h_vec = sin_vangle*rvec + cos_vangle*thvec;
    	sym_tens D = tensor(v_vec, v_vec)*Dv + tensor(h_vec, h_vec)*Dh;

    	eq = dXOdt - dXO16dt*MYR - MYR/R/R * div(rho*(D, grad(XO)))/rho + (rhoV, grad(XO))/rho; 
    	sym_vec nvec = grad(S.zeta);
    	nvec = nvec / sqrt((nvec, nvec));
    	flux = - MYR/R/R*(nvec, (D, grad(XO)));
    	gradXO = (nvec, grad(XO));
    	sym_inited = true;
    }

    S.set_value("XO", comp["O16"]);
	S.set_value("X", comp.X());
    S.set_value("rho", rho);
    S.set_value("vr", vr);
    S.set_value("vt", vt, 11);
    S.set_value("log_R", log(R)*ones(1,1));
    S.set_value("delta", delta*ones(1,1));
    S.set_value("XO0", XOprev);
	S.set_value("X0", Xprev);
    S.set_value("log_R0", lnR0*ones(1,1));
    S.set_value("r0", r0);
    S.set_value("MYR", MYR*ones(1,1));
    S.set_value("mH", HYDROGEN_MASS*ones(1,1));
    S.set_value("Q", Q*ones(1,1));
    S.set_value("sin_vangle", sin(vangle), 11);
    S.set_value("cos_vangle", cos(vangle));

    S.set_map(map);

	matrix K;
	K = opa.xi/(rho*units.rho*eos.cp);

	matrix dOmega_dr, Dmix_v_mean;
	dOmega_dr  = (map.gzz*(D,w)+map.gzt*(w,Dt))/sqrt(map.gzz); 
	matrix Dmix_v;
	Dmix_v_mean = zeros(nr,1);
	for (int l=0; l < nr; l++){
		for (int k=0; k < nth; k++){
			Dmix_v_mean(l) += K(l,k)*r(l,k)*r(l,k)*dOmega_dr(l,k)*dOmega_dr(l,k); 
		}
	}
	Dmix_v_mean /= nth;

	Dmix_v = diffusion_v*Dmix_v_mean*units.Omega*units.Omega; 
	// diffusion_v presents the eta parameter here. 
	// This a free parameter to account for the fact that the brunt-vaisala frequency is not taken into account in the computation of the vertical diffusion coefficient.

    matrix diff_v = ones(nr, nth) * diffusion_v;
    matrix diff_h = ones(nr, nth) * diffusion_h;

    if (conv) {
// Diffusion in the core which is enhanced!!
    	int nc = 0;
    	for (int n = 0; n < conv; n++) nc += map.npts[n];
    	diff_v.setblock(0, nc-1, 0, -1, ones(nc, nth) * diff_coeff_conv);
    	diff_h.setblock(0, nc-1, 0, -1, ones(nc, nth) * diff_coeff_conv);

		if (max(dOmega_dr) > 0){
			for (int j = nc; j < nr; j++) {			
						if (N2()(j,0) <= 0) {
							if (j > nc+10){
							int n = 0, ne = 0;
    						while (1) {
								if (ne + map.npts[n] < j) {
									ne += map.npts[n];
									n++;
								}
								else{
									break;
								}
							}
							diff_v.setblock(ne, -1, 0, -1, ones(nr-ne,nth) * Dmix_v(ne-1));
							break;
							}
						}
						        diff_v.setblock(j, j, 0, -1, ones(1,nth) * Dmix_v(j));

			}
		}
    }
	
    S.set_value("diffusion_v", diff_v);
    S.set_value("diffusion_h", diff_h);

	matrix L16 = zeros(nr,nth);

	for (int i =0; i < nth; i++){
		for (int j = 0; j < nr; j++) {	
				double T9 = T(j,i)/1e9*units.T;
				L16(j,i) = lam16(T9)/HYDROGEN_MASS;

		}
	}

	//matrix dXO16dt = rho*units.rho * comp["H"] *  (-L16*comp["O16"]  + g*L15p*AMASS["O16"]/AMASS["N15"]*comp["N14"]);
	matrix dXO16dt = rho*units.rho * comp["H"] *  (-L16*comp["O16"]);
	S.set_value("dXO16dt", dXO16dt);
	//printf("dXOdt = %e, XOc = %e \n", dXO16dt(0,0)*MYR, comp["O16"](0,0));

    eq.add(op, "XO", "XO");
    eq.add(op, "XO", "rho");
    eq.add(op, "XO", "log_R");
    eq.add(op, "XO", "r");
    eq.add(op, "XO", "vr");
    eq.add(op, "XO", "vt");
    eq.add(op, "XO", "sin_vangle");
    eq.add(op, "XO", "cos_vangle");

    matrix rhs=-eq.eval();
    matrix X = comp["O16"];
    matrix dX = (D, X);
    matrix flux_val = flux.eval();
    matrix gradX_val = gradXO.eval();

    int j0 = 0;
    for (int n = 0; n < ndomains; n++) {
    	int j1 = j0 + map.npts[n] - 1;

    	if (n == conv && conv > 0) {
    		flux.bc_bot2_add(op, n, "XO", "XO");
    		flux.bc_bot2_add(op, n, "XO", "r");
    		flux.bc_bot1_add(op, n, "XO", "XO", -ones(1,nth));
    		flux.bc_bot1_add(op, n, "XO", "r", -ones(1,nth));
    		rhs.setrow(j0, - flux_val.row(j0) + flux_val.row(j0-1));
    	}
    	else {
    		op->bc_bot2_add_l(n, "XO", "XO", 1./map.rz.row(j0), D.block(n).row(0));
    		op->bc_bot2_add_d(n, "XO", "rz", -1./map.rz.row(j0)/map.rz.row(j0)*dX.row(j0));
    		rhs.setrow(j0, -dX.row(j0)/map.rz.row(j0)) ;
    		if (n) {
    			op->bc_bot1_add_l(n, "XO", "XO", -1./map.rz.row(j0-1), D.block(n-1).row(-1));
    			op->bc_bot1_add_d(n, "XO", "rz", 1./map.rz.row(j0-1)/map.rz.row(j0-1)*dX.row(j0-1));
    			rhs.setrow(j0, rhs.row(j0) + dX.row(j0-1)/map.rz.row(j0-1));
    		}
    	}
    	if (n < ndomains - 1) {
    		if (n == conv-1) {
    			op->bc_top1_add_d(n, "XO", "XO", ones(1,nth));
    			op->bc_top2_add_d(n, "XO", "XO", -ones(1,nth));
    			rhs.setrow(j1, -X.row(j1) + X.row(j1+1));
    		}
    		else {
    			op->bc_top1_add_d(n, "XO", "XO", ones(1,nth));
    			op->bc_top2_add_d(n, "XO", "XO", -ones(1,nth));
    			rhs.setrow(j1, -X.row(j1) + X.row(j1+1));
    		}
    	}
    	else {
    		gradXO.bc_top1_add(op, n, "XO", "XO");
    		gradXO.bc_top1_add(op, n, "XO", "r");
    		rhs.setrow(j1, -gradX_val.row(-1)); // no flux at the surface
    	}
    	j0 += map.npts[n];
    }

    op->set_rhs("XO",rhs);
    rhs=zeros(ndomains,1);
}

void star_evol::solve_XC(solver *op) {
    double Q=(4*HYDROGEN_MASS-AMASS["He4"]*UMA)*C_LIGHT*C_LIGHT;
    double diff_coeff_conv = 1e13; // PARAMETER dimensional
    static symbolic S;
    static sym eq, flux, gradXC;
    static bool sym_inited = false;
    if (!sym_inited) {
    	sym XC = S.regvar("XC");
		sym X = S.regconst("X");
    	sym rho = S.regvar("rho");
    	sym vr = S.regvar("vr");
    	sym vt = S.regvar("vt");
    	sym lnR = S.regconst("log_R");
    	sym R = exp(lnR);
    	sym r = S.r;
    	sym XC0 = S.regvar("XC0");
    	sym X0 = S.regvar("X0");
    	sym r0 = S.regvar("r0");
    	sym lnR0 = S.regconst("log_R0");
    	sym delta = S.regconst("delta");
    	sym Dv = S.regvar("diffusion_v");
    	sym Dh = S.regconst("diffusion_h");
    	sym sin_vangle = S.regvar("sin_vangle");
    	sym cos_vangle = S.regvar("cos_vangle");
    	sym MYR = S.regconst("MYR");
    	sym mH = S.regconst("mH");
    	sym Q = S.regconst("Q");
		sym dXC12dt = S.regvar("dXC12dt");

    	sym_vec phivec(COVARIANT);
    	phivec(0) = 0*S.one; phivec(1) = 0*S.one; phivec(2) = S.r*sin(S.theta);
    	sym_vec rvec = grad(S.r);
    	sym_vec thvec = cross(phivec, rvec);

    	sym_vec rhoV = rho*(vr*rvec + vt*thvec);

    	sym drdt = (r-r0)/delta;
    	sym dlnRdt = (lnR-lnR0)/delta;
    	sym dXCdt = (XC-XC0)/delta - (drdt+r*dlnRdt)/S.rz*Dz(XC);
    	sym dXdt = (X-X0)/delta - (drdt+r*dlnRdt)/S.rz*Dz(X);

    	sym_vec v_vec = cos_vangle*rvec - sin_vangle*thvec;
    	sym_vec h_vec = sin_vangle*rvec + cos_vangle*thvec;
    	sym_tens D = tensor(v_vec, v_vec)*Dv + tensor(h_vec, h_vec)*Dh;

    	eq = dXCdt - dXC12dt*MYR - MYR/R/R * div(rho*(D, grad(XC)))/rho + (rhoV, grad(XC))/rho; 
    	sym_vec nvec = grad(S.zeta);
    	nvec = nvec / sqrt((nvec, nvec));
    	flux = - MYR/R/R*(nvec, (D, grad(XC)));
    	gradXC = (nvec, grad(XC));
    	sym_inited = true;
    }

    S.set_value("XC", comp["C12"]);
	S.set_value("X", comp.X());
    S.set_value("rho", rho);
    S.set_value("vr", vr);
    S.set_value("vt", vt, 11);
    S.set_value("log_R", log(R)*ones(1,1));
    S.set_value("delta", delta*ones(1,1));
    S.set_value("XC0", XCprev);
	S.set_value("X0", Xprev);
    S.set_value("log_R0", lnR0*ones(1,1));
    S.set_value("r0", r0);
    S.set_value("MYR", MYR*ones(1,1));
    S.set_value("mH", HYDROGEN_MASS*ones(1,1));
    S.set_value("Q", Q*ones(1,1));
    S.set_value("sin_vangle", sin(vangle), 11);
    S.set_value("cos_vangle", cos(vangle));

    S.set_map(map);

	matrix K;
	K = opa.xi/(rho*units.rho*eos.cp);

	matrix dOmega_dr, Dmix_v_mean;
	dOmega_dr  = (map.gzz*(D,w)+map.gzt*(w,Dt))/sqrt(map.gzz); 
	matrix Dmix_v;
	Dmix_v_mean = zeros(nr,1);
	for (int l=0; l < nr; l++){
		for (int k=0; k < nth; k++){
			Dmix_v_mean(l) += K(l,k)*r(l,k)*r(l,k)*dOmega_dr(l,k)*dOmega_dr(l,k); 
		}
	}
	Dmix_v_mean /= nth;

	Dmix_v = diffusion_v*Dmix_v_mean*units.Omega*units.Omega; 
	// diffusion_v presents the eta parameter here. 
	// This a free parameter to account for the fact that the brunt-vaisala frequency is not taken into account in the computation of the vertical diffusion coefficient.

    matrix diff_v = ones(nr, nth) * diffusion_v;
    matrix diff_h = ones(nr, nth) * diffusion_h;

    if (conv) {
// Diffusion in the core which is enhanced!!
    	int nc = 0;
    	for (int n = 0; n < conv; n++) nc += map.npts[n];
    	diff_v.setblock(0, nc-1, 0, -1, ones(nc, nth) * diff_coeff_conv);
    	diff_h.setblock(0, nc-1, 0, -1, ones(nc, nth) * diff_coeff_conv);

		if (max(dOmega_dr) > 0){
			for (int j = nc; j < nr; j++) {			
						if (N2()(j,0) <= 0) {
							if (j > nc+10){
							int n = 0, ne = 0;
    						while (1) {
								if (ne + map.npts[n] < j) {
									ne += map.npts[n];
									n++;
								}
								else{
									break;
								}
							}
							diff_v.setblock(ne, -1, 0, -1, ones(nr-ne,nth) * Dmix_v(ne-1));
							break;
							}
						}
						        diff_v.setblock(j, j, 0, -1, ones(1,nth) * Dmix_v(j));

			}
		}
		//comp["C12"].setblock(0, nc-1, 0, -1, zeros(nc, nth));
    }
	
    S.set_value("diffusion_v", diff_v);
    S.set_value("diffusion_h", diff_h);

	matrix L12 = zeros(nr,nth);

	for (int i =0; i < nth; i++){
		for (int j = 0; j < nr; j++) {	
				double T9 = T(j,i)/1e9*units.T;
				L12(j,i) = lam12(T9)/HYDROGEN_MASS;
		}
	}

	//matrix dXC12dt = rho*units.rho * comp["H"] *  (-L12*comp["C12"]  + g*L15*AMASS["C12"]/AMASS["N15"]*comp["N14"]);
	matrix dXC12dt = rho*units.rho * comp["H"] *  (-L12*comp["C12"]); // + L14*AMASS["N15"]/AMASS["N14"]*comp["N14"]);
	S.set_value("dXC12dt", dXC12dt);
	//printf("dXCdt = %e, Xc = %e, XNc = %e, XOc = %e, XCc = %e \n", dXC12dt(0,0)*MYR, comp["H"](0,0), comp["N14"](0,0), comp["O16"](0,0), comp["C12"](0,0));

    eq.add(op, "XC", "XC");
    eq.add(op, "XC", "rho");
    eq.add(op, "XC", "log_R");
    eq.add(op, "XC", "r");
    eq.add(op, "XC", "vr");
    eq.add(op, "XC", "vt");
    eq.add(op, "XC", "sin_vangle");
    eq.add(op, "XC", "cos_vangle");

    matrix rhs=-eq.eval();
    matrix X = comp["C12"];
    matrix dX = (D, X);
    matrix flux_val = flux.eval();
    matrix gradX_val = gradXC.eval();

    int j0 = 0;
    for (int n = 0; n < ndomains; n++) {
    	int j1 = j0 + map.npts[n] - 1;

    	if (n == conv && conv > 0) {
    		flux.bc_bot2_add(op, n, "XC", "XC");
    		flux.bc_bot2_add(op, n, "XC", "r");
    		flux.bc_bot1_add(op, n, "XC", "XC", -ones(1,nth));
    		flux.bc_bot1_add(op, n, "XC", "r", -ones(1,nth));
    		rhs.setrow(j0, - flux_val.row(j0) + flux_val.row(j0-1));
    	}
    	else {
    		op->bc_bot2_add_l(n, "XC", "XC", 1./map.rz.row(j0), D.block(n).row(0));
    		op->bc_bot2_add_d(n, "XC", "rz", -1./map.rz.row(j0)/map.rz.row(j0)*dX.row(j0));
    		rhs.setrow(j0, -dX.row(j0)/map.rz.row(j0)) ;
    		if (n) {
    			op->bc_bot1_add_l(n, "XC", "XC", -1./map.rz.row(j0-1), D.block(n-1).row(-1));
    			op->bc_bot1_add_d(n, "XC", "rz", 1./map.rz.row(j0-1)/map.rz.row(j0-1)*dX.row(j0-1));
    			rhs.setrow(j0, rhs.row(j0) + dX.row(j0-1)/map.rz.row(j0-1));
    		}
    	}
    	if (n < ndomains - 1) {
    		if (n == conv-1) {
    			op->bc_top1_add_d(n, "XC", "XC", ones(1,nth));
    			op->bc_top2_add_d(n, "XC", "XC", -ones(1,nth));
    			rhs.setrow(j1, -X.row(j1) + X.row(j1+1));
    		}
    		else {
    			op->bc_top1_add_d(n, "XC", "XC", ones(1,nth));
    			op->bc_top2_add_d(n, "XC", "XC", -ones(1,nth));
    			rhs.setrow(j1, -X.row(j1) + X.row(j1+1));
    		}
    	}
    	else {
    		gradXC.bc_top1_add(op, n, "XC", "XC");
    		gradXC.bc_top1_add(op, n, "XC", "r");
    		rhs.setrow(j1, -gradX_val.row(-1)); // no flux at the surface
    	}
    	j0 += map.npts[n];
    }

    op->set_rhs("XC",rhs);
    rhs=zeros(ndomains,1);
}

// Continuity equation
void star_evol::solve_cont(solver *op) {

	star2d::solve_cont(op);

	static symbolic S;
	static sym eq, flux, reg_cont, bc_cs;
	static bool sym_inited = false;
	if (!sym_inited) {
		sym rho = S.regvar("rho");
		sym vr = S.regvar("vr");
		sym lnrhoc = S.regconst("log_rhoc");
		sym lnR = S.regconst("log_R");
		sym R = exp(lnR);
		sym r = S.r;
		sym rho0 = S.regvar("rho0");
		sym lnrhoc0 = S.regconst("log_rhoc0");
		sym r0 = S.regvar("r0");
		sym lnR0 = S.regconst("log_R0");
		sym delta = S.regconst("delta");
		sym cp = S.regvar("eos.cp");
		sym cv = S.regvar("eos.cv");
		sym p  = S.regvar("p");

		sym drdt = (r-r0)/delta;
		sym dlnRdt = (lnR-lnR0)/delta;
		sym drhodt = (rho-rho0)/delta - (drdt+r*dlnRdt)/S.rz*Dz(rho);
		sym dlnrhocdt = (lnrhoc - lnrhoc0)/delta;
		eq = drhodt + rho*dlnrhocdt;
		sym_vec nvec = grad(S.zeta);
		nvec = nvec / sqrt((nvec, nvec));
		sym_vec rvec = grad(r);
		flux = -rho * (rvec, nvec) * (r*dlnRdt + drdt);

		bc_cs = (rvec, nvec) * (r*dlnRdt + drdt) + sqrt(cp/cv*p/rho); // sound speed

		reg_cont = 3*S.Dz(rho*vr)/S.rz + drhodt + rho*dlnrhocdt;

		sym_inited = true;
	}

	S.set_value("rho", rho);
	S.set_value("vr", vr);
	S.set_value("log_rhoc", log(rhoc)*ones(1,1));
	S.set_value("log_R", log(R)*ones(1,1));
	S.set_value("rho0", rho0);
	S.set_value("log_rhoc0", lnrhoc0*ones(1,1));
	S.set_value("r0", r0);
	S.set_value("log_R0", lnR0*ones(1,1));
	S.set_value("delta", delta*ones(1,1));
	S.set_value("eos.cp", eos.cp);
	S.set_value("eos.cv", eos.cv);
	S.set_value("p", p);

	S.set_map(map);

	eq.add(op, "vr", "rho");
	eq.add(op, "vr", "log_rhoc");
	eq.add(op, "vr", "log_R");
	eq.add(op, "vr", "r");

	matrix rhs = -eq.eval();
	matrix flux_val = flux.eval();

	int j0 = 0;
	for (int n = 0; n < ndomains; n++) {
		int j1 = j0 + map.npts[n] - 1;

		if (n == 0) {
			rhs.setrow(j0, zeros(1, nth));
		}

		if (n == conv-1) { // conv-1 domain just below interface
			// Here we impose mass flux continuity
			flux.bc_top1_add(op, n, "vr", "rho");
			flux.bc_top1_add(op, n, "vr", "log_R");
			flux.bc_top1_add(op, n, "vr", "r");
			flux.bc_top2_add(op, n, "vr", "rho", -ones(1, nth));
			flux.bc_top2_add(op, n, "vr", "log_R", -ones(1, nth));
			flux.bc_top2_add(op, n, "vr", "r", -ones(1, nth));
			rhs.setrow(j1, -flux_val.row(j1) + flux_val.row(j1+1));
		}
		else if (n == ndomains - 1) {
			// Here zero mass flux
			flux.bc_top1_add(op, n, "vr", "rho");
			flux.bc_top1_add(op, n, "vr", "log_R");
			flux.bc_top1_add(op, n, "vr", "r");
			rhs.setrow(j1, -flux_val.row(j1));

			//bc_cs.bc_top1_add(op, n, "vr", "rho");
			//bc_cs.bc_top1_add(op, n, "vr", "r");
			//bc_cs.bc_top1_add(op, n, "vr", "log_R");
			//bc_cs.bc_top1_add(op, n, "vr", "p");
			//rhs.setrow(j1, -bc_cs.eval().row(j1));

		}
		else {
			rhs.setrow(j1, zeros(1, nth));
		}
		j0 += map.npts[n];
	}

	op->set_rhs("vr", op->get_rhs("vr") + rhs);

// Now we need to regularize continuity equation at the center where rho/r
// is singular
	for(int n = 0; n < ndomains; n++) {
// We first apply the definition of reg_cont:
		if(n == 0) {
			reg_cont.bc_bot2_add(op, 0, "reg_cont", "vr");
			reg_cont.bc_bot2_add(op, 0, "reg_cont", "rho");
			reg_cont.bc_bot2_add(op, 0, "reg_cont", "r");
			reg_cont.bc_bot2_add(op, 0, "reg_cont", "log_rhoc");
			op->bc_bot2_add_d(0, "reg_cont", "reg_cont", -ones(1, nth));
		} else {
			op->bc_bot2_add_d(n, "reg_cont", "reg_cont", ones(1,nth));
			op->bc_bot1_add_d(n, "reg_cont", "reg_cont", -ones(1,nth));
		}
	}
	op->set_rhs("reg_cont", zeros(ndomains, nth));

// Then we say that Mass Flux is zero at center, in fact that rec_cont averaged over sphere
// is zero
	rhs=zeros(ndomains,1);
	for(int n = 0; n < ndomains; n++) {
		if(n == ndomains - 1) {
			op->bc_top1_add_r(n, "log_M", "reg_cont", ones(1,1), map.It);
			rhs(-1) = -(reg_cont.eval().row(0), map.It)(0);
		} else {
			op->bc_top1_add_d(n, "log_M", "log_M", ones(1,1));
			op->bc_top2_add_d(n, "log_M", "log_M", -ones(1,1));
		}
	}
	op->set_rhs("log_M", rhs);

}

void star_evol::solve_temp(solver *op) {
	star2d::solve_temp(op);

	static symbolic S;
	static sym eq;
	static bool sym_inited = false;

	if (!sym_inited) {
		sym_inited = true;
		sym T = S.regvar("T");
		sym lnTc = S.regconst("log_Tc");
		sym lnp = S.regvar("log_p");
		sym lnpc = S.regconst("log_pc");
		sym rho = S.regvar("rho");
		sym cp = S.regvar("eos.cp");
		sym del_ad = S.regvar("eos.del_ad");
		sym lnR = S.regconst("log_R");
		sym r = S.r;
		sym T0 = S.regvar("T0");
		sym lnTc0 = S.regconst("log_Tc0");
		sym lnp0 = S.regconst("log_p0");
		sym lnpc0 = S.regconst("log_pc0");
		sym r0 = S.regvar("r0");
		sym lnR0 = S.regconst("log_R0");
		sym delta = S.regconst("delta");
		sym MYR = S.regconst("MYR");
		sym drdt = (r-r0)/delta;
		sym dlnRdt = (lnR-lnR0)/delta;
		sym dTdt = (T-T0)/delta - (drdt+r*dlnRdt)/S.rz*Dz(T);
		sym dlnpdt = (lnp-lnp0)/delta - (drdt+r*dlnRdt)/S.rz*Dz(lnp);
		sym dlnTcdt = (lnTc-lnTc0)/delta;
		sym dlnpcdt = (lnpc-lnpc0)/delta;
		eq = rho * cp * exp(lnTc) / MYR * (dTdt + T * dlnTcdt - del_ad * T * (dlnpdt + dlnpcdt));

	}

	S.set_value("T", T);
	S.set_value("log_Tc", log(Tc)*ones(1,1));
	S.set_value("log_p", log(p));
	S.set_value("log_pc", log(pc)*ones(1,1));
	S.set_value("rho", rho);
	S.set_value("eos.cp", eos.cp);
	S.set_value("eos.del_ad", eos.del_ad);
	S.set_value("log_R", log(R)*ones(1,1));
	S.set_value("T0", T0);
	S.set_value("log_Tc0", lnTc0*ones(1,1));
	S.set_value("log_p0", lnp0);
	S.set_value("log_pc0", lnpc0*ones(1,1));
	S.set_value("r0", r0);
	S.set_value("log_R0", lnR0*ones(1,1));
	S.set_value("delta", delta*ones(1,1));
	S.set_value("MYR", MYR*ones(1,1));
	S.set_map(map);

	eq.add(op, "log_T", "T");
	eq.add(op, "log_T", "log_Tc");
	eq.add(op, "log_T", "log_p");
	eq.add(op, "log_T", "log_pc");
	eq.add(op, "log_T", "rho");
	eq.add(op, "log_T", "log_R");
	eq.add(op, "log_T", "r");

	matrix rhs = op->get_rhs("log_T"); // recup from the steady operator
	matrix rhs2 = -eq.eval(); //
	int j0 = 0;
	for (int n = 0; n < ndomains; n++) {
		int j1 = j0 + map.npts[n] - 1;
		rhs2.setrow(j0, zeros(1,nth));
		rhs2.setrow(j1, zeros(1,nth));
		j0 += map.npts[n];
	}

	op->set_rhs("log_T", rhs + rhs2);

}

void star_evol::solve_mov(solver *op) {

    star2d::solve_mov(op); // use first the steady operator

    if(Omega == 0) return;

	static bool sym_inited = false;
	static symbolic S;
	static sym eq, bc_t_add, eq_t;

	if(!sym_inited) { // add the time derivative of Omega
		sym_inited = true;

		sym w = S.regvar("w");
		sym rho = S.regvar("rho");
		sym lnrhoc = S.regconst("log_rhoc");
		sym lnpc = S.regconst("log_pc");
		sym lnR = S.regconst("log_R");
		sym R = exp(lnR);
		sym r = S.r;
		sym w0 = S.regvar("w0");
		sym r0 = S.regvar("r0");
		sym lnrhoc0 = S.regconst("log_rhoc0");
		sym lnpc0 = S.regconst("log_pc0");
		sym lnR0 = S.regconst("log_R0");
		sym delta = S.regconst("delta");

		sym s = r*sin(S.theta);

		sym drdt = (r-r0)/delta;
		sym dlnRdt = (lnR-lnR0)/delta;
		sym dwdt = (w-w0)/delta - (drdt+r*dlnRdt)/S.rz*Dz(w);
		sym dlnrhocdt = (lnrhoc-lnrhoc0)/delta;
		sym dlnpcdt = (lnpc-lnpc0)/delta;
		eq = rho*s*s*dwdt + rho*s*s*w*(-dlnRdt + 0.5*dlnpcdt - 0.5*dlnrhocdt);

	}

	S.set_value("w",w);
	S.set_value("rho", rho);
	S.set_value("log_rhoc", log(rhoc)*ones(1, 1));
	S.set_value("log_pc", log(pc)*ones(1, 1));
	S.set_value("log_R", log(R)*ones(1, 1));
	S.set_value("w0", w0);
	S.set_value("r0", r0);
	S.set_value("log_rhoc0", lnrhoc0*ones(1, 1));
	S.set_value("log_pc0", lnpc0*ones(1, 1));
	S.set_value("log_R0", lnR0*ones(1, 1));
	S.set_value("delta", delta*ones(1,1));
	S.set_map(map);

	// Add new terms to eq. "w"

	eq.add(op, "w", "w");
	eq.add(op, "w", "rho");
	eq.add(op, "w", "log_rhoc");
	eq.add(op, "w", "log_pc");
	eq.add(op, "w", "log_R");
	eq.add(op, "w", "r");

	matrix rhs = op->get_rhs("w");
	matrix rhs2 = -eq.eval();
	int j0 = 0;
	for (int n = 0; n < ndomains; n++) {
		int j1 = j0 + map.npts[n] - 1;
		rhs2.setrow(j0, zeros(1,nth));
		rhs2.setrow(j1, zeros(1,nth));
		j0 += map.npts[n];
	}

	rhs = rhs + rhs2;
// Now we need to change the central condition for Omega
// dOmega/dr=0 at centre.
	op->reset_bc_bot(0, "w");
	op->bc_bot2_add_l(0, "w", "w", ones(1, nth), D.block(0).row(0));
	rhs.setrow(0, -(D, w).row(0));

	op->set_rhs("w", rhs);

// Remove Omega0 equation
	op->reset("Omega0");
	op->bc_bot2_add_d(0, "Omega0", "Omega0", ones(1,1));
	op->set_rhs("Omega0", zeros(1,1));

	/*
	if (1) { // Surface pressure constant in time
		op->reset("pi_c");
		rhs=zeros(ndomains,1);
		j0=0;
		for(int n=0;n<ndomains;n++) {
			if(n<ndomains-1) {
				op->bc_top1_add_d(n,"pi_c","pi_c",ones(1,1));
				op->bc_top2_add_d(n,"pi_c","pi_c",-ones(1,1));
			} else {
				matrix TT;
				map.leg.eval_00(th,0,TT);
				op->bc_top1_add_d(n,"pi_c","log_pc",ones(1,1));
				op->bc_top1_add_r(n,"pi_c","log_p",ones(1,1),TT);
				rhs(ndomains-1)=0;
			}

			j0+=map.gl.npts[n];
		}
		op->set_rhs("pi_c",rhs);
	}
	*/
}


int star_evol::remove_convective_core() {
	if (conv>1) { // see star_map
		star2d::remove_convective_core();
		return 0;
	}
	double dp0 = -log(p(map.npts[0], 0));
	double dp1 = -dp0 - log(p(map.npts[0]+map.npts[1], 0));
	domain_weight[0] = domain_weight[1]*dp1/dp0; // adapt the pressure drop in each domain
	// here we want to keep the same size of the domain once the core has disappeared
	star2d::remove_convective_core();
	return 1;
}

// The Newton solver:
double star_evol::solve(solver *op, matrix_map& error_map, int nit) {

	double err = star2d::solve(op, error_map, nit);
	calcTimeDerivs(); // For storage

	return err;
}

