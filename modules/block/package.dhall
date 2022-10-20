let Configuration = < Ahci : {} >

in  { Type = Configuration
    , toChild =
        λ(cfg : Configuration) → merge { Ahci = ./drivers/ahci.dhall } cfg
    }
