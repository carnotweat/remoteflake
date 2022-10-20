let Configuration = < Ext2 : {} >

in  { Type = Configuration
    , toChildren =
        λ(cfg : Configuration) → merge { Ext2 = ./drivers/ext2.dhall } cfg
    }
