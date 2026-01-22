{ inputs, lib, config, ... }:
let
  inherit (inputs.helper-tools.lib) mkSecrets;
  cfg = config.custom.apps.immich;
in
{
  config = lib.mkIf cfg.enable {
    sops = {
      secrets = mkSecrets [
        "immich/pocket/client_id"
        "immich/pocket/client_secret"
      ]
        config.custom.base.secrets.podman;

      templates."immich/config.json" = {
        restartUnits = [ "immich.service" "immich-microservices.service" ];
        owner = cfg.user.name;
        content = ''
          {
            "backup": {
              "database": {
                "cronExpression": "0 02 * * *",
                "enabled": true,
                "keepLastAmount": 14
              }
            },
            "ffmpeg": {
              "accel": "qsv",
              "accelDecode": true,
              "acceptedAudioCodecs": [
                "aac",
                "mp3",
                "libopus",
                "pcm_s16le"
              ],
              "acceptedContainers": [
                "mov",
                "ogg",
                "webm"
              ],
              "acceptedVideoCodecs": [
                "h264"
              ],
              "bframes": -1,
              "cqMode": "auto",
              "crf": 23,
              "gopSize": 0,
              "maxBitrate": "0",
              "preferredHwDevice": "auto",
              "preset": "ultrafast",
              "refs": 0,
              "targetAudioCodec": "aac",
              "targetResolution": "1080",
              "targetVideoCodec": "h264",
              "temporalAQ": false,
              "threads": 0,
              "tonemap": "hable",
              "transcode": "disabled",
              "twoPass": false
            },
            "image": {
              "colorspace": "p3",
              "extractEmbedded": false,
              "fullsize": {
                "enabled": false,
                "format": "jpeg",
                "quality": 80
              },
              "preview": {
                "format": "jpeg",
                "quality": 80,
                "size": 1440
              },
              "thumbnail": {
                "format": "webp",
                "quality": 80,
                "size": 250
              }
            },
            "job": {
              "backgroundTask": {
                "concurrency": 5
              },
              "faceDetection": {
                "concurrency": 2
              },
              "library": {
                "concurrency": 5
              },
              "metadataExtraction": {
                "concurrency": 5
              },
              "migration": {
                "concurrency": 5
              },
              "notifications": {
                "concurrency": 5
              },
              "ocr": {
                "concurrency": 1
              },
              "search": {
                "concurrency": 5
              },
              "sidecar": {
                "concurrency": 5
              },
              "smartSearch": {
                "concurrency": 2
              },
              "thumbnailGeneration": {
                "concurrency": 3
              },
              "videoConversion": {
                "concurrency": 1
              }
            },
            "library": {
              "scan": {
                "cronExpression": "0 0 * * *",
                "enabled": true
              },
              "watch": {
                "enabled": false
              }
            },
            "logging": {
              "enabled": true,
              "level": "log"
            },
            "machineLearning": {
              "availabilityChecks": {
                "enabled": true,
                "interval": 30000,
                "timeout": 2000
              },
              "clip": {
                "enabled": true,
                "modelName": "ViT-SO400M-16-SigLIP2-384__webli"
              },
              "duplicateDetection": {
                "enabled": true,
                "maxDistance": 0.001
              },
              "enabled": true,
              "facialRecognition": {
                "enabled": true,
                "maxDistance": 0.5,
                "minFaces": 10,
                "minScore": 0.7,
                "modelName": "antelopev2"
              },
              "ocr": {
                "enabled": true,
                "maxResolution": 736,
                "minDetectionScore": 0.5,
                "minRecognitionScore": 0.8,
                "modelName": "PP-OCRv5_mobile"
              },
              "urls": [
                "http://immich-learning:3003"
              ]
            },
            "map": {
              "darkStyle": "https://tiles.immich.cloud/v1/style/dark.json",
              "enabled": true,
              "lightStyle": "https://tiles.immich.cloud/v1/style/light.json"
            },
            "metadata": {
              "faces": {
                "import": false
              }
            },
            "newVersionCheck": {
              "enabled": true
            },
            "nightlyTasks": {
              "clusterNewFaces": true,
              "databaseCleanup": true,
              "generateMemories": true,
              "missingThumbnails": true,
              "startTime": "00:00",
              "syncQuotaUsage": true
            },
            "notifications": {
              "smtp": {
                "enabled": false,
                "from": "",
                "replyTo": "",
                "transport": {
                  "host": "",
                  "ignoreCert": false,
                  "password": "",
                  "port": 587,
                  "secure": false,
                  "username": ""
                }
              }
            },
            "oauth": {
              "autoLaunch": true,
              "autoRegister": true,
              "buttonText": "Login with Pocket ID",
              "clientId": "${config.sops.placeholder."immich/pocket/client_id"}",
              "clientSecret": "${config.sops.placeholder."immich/pocket/client_secret"}",
              "defaultStorageQuota": 250,
              "enabled": true,
              "issuerUrl": "https://pocket.${config.custom.apps.settings.domain}",
              "mobileOverrideEnabled": false,
              "mobileRedirectUri": "",
              "profileSigningAlgorithm": "none",
              "roleClaim": "immich_role",
              "scope": "openid email profile",
              "signingAlgorithm": "RS256",
              "storageLabelClaim": "preferred_username",
              "storageQuotaClaim": "immich_quota",
              "timeout": 30000,
              "tokenEndpointAuthMethod": "client_secret_post"
            },
            "passwordLogin": {
              "enabled": false
            },
            "reverseGeocoding": {
              "enabled": true
            },
            "server": {
              "externalDomain": "https://immich.${config.custom.apps.settings.domain}",
              "loginPageMessage": "",
              "publicUsers": true
            },
            "storageTemplate": {
              "enabled": true,
              "hashVerificationEnabled": true,
              "template": "{{y}}/{{y}}-{{MM}}-{{dd}}/{{filename}}"
            },
            "templates": {
              "email": {
                "albumInviteTemplate": "",
                "albumUpdateTemplate": "",
                "welcomeTemplate": ""
              }
            },
            "theme": {
              "customCss": ""
            },
            "trash": {
              "days": 30,
              "enabled": true
            },
            "user": {
              "deleteDelay": 7
            }
          }
        '';
      };
    };
  };
}
