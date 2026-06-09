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
    split_interface = false
    interface_name = czm_boundary
  []
[]

[UserObjects]
  [euler_angles]
    type = PropertyReadFile
    nprop = 3
    prop_file_name = 'euler_3.txt'
    read_type = 'block'
    nblock = 3
    use_zero_based_block_indexing = false
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
    
    [CohesiveZone]
      [all]
        boundary = czm_boundary #'561 562 564' 
        strain = SMALL
        verbose = true
        #base_name = czm_test
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
  [therm_prefactor]
    type = DerivativeParsedMaterial
    coupled_variables = 'CTE_0 temp'
    property_name = therm_prefactor
    constant_names = 'm_cte T'
    constant_expressions = '2.6e-5 298' #'2.65e-5 298'
    expression = 'CTE_0*(temp-T)' #'(CTE_0*((1+m_cte)*irr)*(temp-T))'
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

  [czm]
    type = BiLinearMixedModeTraction
    boundary = czm_boundary # '561 562 564' - This is one sideset from each interface, but using this doesn't seem to affect the results.
    penalty_stiffness = 1e13
    GI_c = 1e4
    GII_c =1e5
    normal_strength = 1e6
    shear_strength = 1e3
    displacements = 'disp_x disp_y'
    eta = 2.2
    viscosity = 1e3
    # base_name = 'czm_test'
    # lag_mode_mixity = true
    # lag_displacement_jump = true
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
  dt = 1
  end_time = 1

[]

[Outputs]
  exodus = true
  csv = true
[]



