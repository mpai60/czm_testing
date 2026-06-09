[Mesh]

  construct_side_list_from_node_list=true

  [tess]
    type = FileMeshGenerator
    file = 'test_3_refine.msh'
    #file=  'oriented.msh'
  []

  [right_boundary]
    type = BoundingBoxNodeSetGenerator
    input = tess
    new_boundary = 560
    bottom_left = '0.9999999 -0.2 0'
    top_right = '1.2 1.2 0'
  []

  [bottom_boundary]
    type = BoundingBoxNodeSetGenerator
    input = right_boundary
    new_boundary = 559
    bottom_left = '-0.2 -0.2 0'
    top_right = '1.2 0.00015 0'
  []

  [breakmesh]
    type = BreakMeshByBlockGenerator
    input = bottom_boundary
  []
  [secondary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    input = breakmesh
    new_block_id = 5
    sidesets = '563 565 566'
  []

  [primary_subdomain]
    type = LowerDBlockFromSidesetGenerator
    new_block_id = 4
    input = secondary_subdomain
    sidesets = '561 562 564'
  []

[]


[UserObjects]
  [euler_angles]
    type = PropertyReadFile
    nprop = 3
    prop_file_name = 'euler_3.txt'
    read_type = 'block'
    nblock = 5
    use_zero_based_block_indexing = false
  []

  [czm_uo]
    type = BilinearMixedModeCohesiveZoneModel
    disp_x = disp_x
    disp_y = disp_y
    displacements = 'disp_x disp_y'
    penalty = 1e13
    penalty_stiffness = 1e6

    primary_boundary = 561
    secondary_boundary = 563
    primary_subdomain = 4
    secondary_subdomain = 5
    secondary_variable = disp_x

    friction_coefficient = 0.1 
    penalty_friction = 0e4
    use_physical_gap = true

    # bilinear parameters
    normal_strength = 1e6
    shear_strength = 1e3

    power_law_parameter = 2.2
    viscosity = 1.0e-3
    GI_c = 1e3
    GII_c =1e2

  []

[]




[Constraints]
  [x]
    type = NormalMortarMechanicalContact
    primary_boundary = 561
    secondary_boundary = 563
    primary_subdomain = 4
    secondary_subdomain = 5
    secondary_variable = disp_x
    component = x
    use_displaced_mesh = true
    compute_lm_residuals = false
    weighted_gap_uo = czm_uo
    correct_edge_dropping = true
  []
  [y]
    type = NormalMortarMechanicalContact
    primary_boundary = 561
    secondary_boundary = 563
    primary_subdomain = 4
    secondary_subdomain = 5
    secondary_variable = disp_y
    component = y
    use_displaced_mesh = true
    compute_lm_residuals = false
    weighted_gap_uo = czm_uo
    correct_edge_dropping = true
  []
  [c_x]
    type = MortarGenericTraction
    primary_boundary = 561
    secondary_boundary = 563
    primary_subdomain = 4
    secondary_subdomain = 5
    secondary_variable = disp_x
    component = x
    use_displaced_mesh = true
    compute_lm_residuals = false
    cohesive_zone_uo = czm_uo
  []
  [c_y]
    type = MortarGenericTraction
    primary_boundary = 561
    secondary_boundary = 563
    primary_subdomain = 4
    secondary_subdomain = 5
    secondary_variable = disp_y
    component = y
    use_displaced_mesh = true
    compute_lm_residuals = false
    cohesive_zone_uo = czm_uo
  []
[]

##################################################################################
[GlobalParams]
  displacements = 'disp_x disp_y'
[]

[Variables]
  [disp_x]
    order = FIRST
    family = LAGRANGE
  []
  [disp_y]
    order = FIRST
    family = LAGRANGE
  []
[]

[AuxVariables]
  [temp]
    order = CONSTANT
    family = MONOMIAL
  []
  [irr]
    order = CONSTANT
    family = MONOMIAL
  []
  [m_ec]
    order = CONSTANT
    family = MONOMIAL
  []
  [m_ea]
    order = CONSTANT
    family = MONOMIAL
  []
  [m_vc]
    order = CONSTANT
    family = MONOMIAL
  []
  [CTE_0]
    order = CONSTANT
    family = MONOMIAL
  []
[]

###################################################################################
[Functions]

  [temp_def]
    type = ConstantFunction
    value = 800
  []
  [irr_def]
    type = ConstantFunction
    value = 2
  []
  [m_ec_def]
    type = ConstantFunction
    value = -0.01
  []
  [m_ea_def]
    type = ConstantFunction
    value = 0.05
  []
  [m_vc_def]
    type = ConstantFunction
    value = -0.01
  []
  [CTE_0_def]
    type = ConstantFunction
    value = 1.3e-5
  []
[]



###################################################################################
[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        eigenstrain_names = 'thermal_strain irr_strain'
        add_variables = true
        generate_output = 'vonmises_stress'
      []
    []
  []
[]

###################################################################################
[AuxKernels]
  [tempfuncaux]
    type = FunctionAux
    variable = temp
    function = temp_def
    use_displaced_mesh = false
  []
  [irrfuncaux]
    type = FunctionAux
    variable = irr
    function = irr_def
    use_displaced_mesh = false
  []
  [cte0funcaux]
    type = FunctionAux
    variable = CTE_0
    function = CTE_0_def
    use_displaced_mesh = false
  []
  [mvcfuncaux]
    type = FunctionAux
    variable = m_vc
    function = m_vc_def
    use_displaced_mesh = false
  []
  [mecfuncaux]
    type = FunctionAux
    variable = m_ec
    function = m_ec_def
    use_displaced_mesh = false
  []
  [meafuncaux]
    type = FunctionAux
    variable = m_ea
    function = m_ea_def
    use_displaced_mesh = false
  []
[]

###################################################################################
[BCs]
  [right]
    type = DirichletBC
    boundary = 560
    variable = disp_x
    value = 0.
  []

  [bottom]
    type = DirichletBC
    boundary = 559
    variable = disp_y
    value = 0.
  []  
[]



###################################################################################
[Materials]

  [E11]
    type = DerivativeParsedMaterial
    property_name = 'E11'
    coupled_variables = 'm_ea irr'
    constant_names = 'ea_0'
    constant_expressions = '1.095e12'
    expression = '(1+(m_ea*irr))*ea_0'
  []
  [E22]
    type = DerivativeParsedMaterial
    property_name = 'E22'
    coupled_variables = 'm_ec irr'
    constant_names = 'ec_0'
    constant_expressions = '3.65e10'
    expression = '(1+(m_ec*irr))*ec_0'
  []
  [G12]
    type = DerivativeParsedMaterial
    property_name = 'G12'  
    constant_names = 'm'
    constant_expressions = '2.8568e8'
    expression = 'm'
  []
  [G23]
    type = DerivativeParsedMaterial
    property_name = 'G23' 
    constant_names = 'm'
    constant_expressions = '9.549e6'
    expression = 'm'
  []
  [G31]
    type = DerivativeParsedMaterial
    property_name = 'G31'
    constant_names = 'm'
    constant_expressions = '2.8568e8'
    expression = 'm'
  []
  [nu12]
    type = DerivativeParsedMaterial
    property_name = 'nu12'
    coupled_variables = 'm_vc m_ea m_ec irr'
    constant_names = 'vc_0 ea_0 ec_0'
    constant_expressions = '0.3 1.095e12 3.65e10'
    expression = '((1+(m_ec*irr))*ec_0)*((1+(m_vc*irr))*vc_0)/((1+(m_ea*irr))*ea_0)'
  []
  [nu23]
    type = DerivativeParsedMaterial
    property_name = 'nu23'
    coupled_variables = 'm_vc irr'
    constant_names = 'vc_0'
    constant_expressions = '0.3'
    expression = '(1+(m_vc*irr))*vc_0'
  []
  [therm_prefactor]
    type = DerivativeParsedMaterial
    coupled_variables = 'CTE_0 temp'
    property_name = therm_prefactor
    constant_names = 'm_cte T'
    constant_expressions = '2.6e-5 298' 
    expression = 'CTE_0*(temp-T)' 
  []
  [thermal_strain]
    type = ComputeVariableEigenstrain
    eigen_base = '-0.0577 0 0 0 1 0 0 0 1'
    args = 'temp'
    prefactor = therm_prefactor
    eigenstrain_name = thermal_strain
  []
  [irr_prefactor]
    type = DerivativeParsedMaterial
    #block = '100'
    coupled_variables = 'irr'
    property_name = irr_prefactor
    constant_names = 'm'
    constant_expressions = '1.185'
    expression = '((m*irr)/100)'
  []
  [irr_strain]
    type = ComputeVariableEigenstrain
    eigen_base = '-0.31 0 0 0 1 0 0 0 1'
    args = 'irr'
    prefactor = irr_prefactor
    eigenstrain_name = irr_strain
  []
  [elasticity_tensor]
    type = ComputeElasticityTensorCP
    C_ijkl = '1.095e12 3.65e10 1.095e12 2.8568e8 9.549e6 9.549e6 0.01 0.01 0.3 0.3 0.01 0.01' 
    fill_method = orthotropic
    read_prop_user_object = euler_angles
  []

  [stress]
    type = ComputeLinearElasticStress
  []
[]

[Preconditioning]
  [prec1]
    type = SMP
    full = true
  []
[]


[Executioner]
  type = Transient

  solve_type = 'NEWTON'
  line_search = none

  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'

  automatic_scaling = true
  nl_abs_tol = 1.2e-17
  dt = 1
  end_time = 1
[]

[Outputs]
  exodus = true
  csv = true
[]





