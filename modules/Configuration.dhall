-- SPDX-License-Identifier: CC0-1.0

let Genode = ./Genode.dhall

let Block = ./block/package.dhall

let Framebuffer = ./framebuffer/package.dhall

let Storage = ./storage/package.dhall

let Configuration
    : Type
    = { block : Block.Type
      , framebuffer : Framebuffer.Type
      , input : { filterConfig : Genode.Init.Config.Type }
      , storage : Storage.Type
      }

in  Configuration
